import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_config.dart';
import '../models/eco_point.dart';
import '../services/eco_point_service.dart';
import 'ecoscan_store.dart';

enum MapTileStyle { dark, streets, satellite }

class EcoPointController extends ChangeNotifier {
  EcoPointController({
    required EcoPointService service,
    required EcoScanStore store,
  }) : this._(service, store);

  EcoPointController._(this._service, this._store);

  final EcoPointService _service;
  final EcoScanStore _store;
  final Map<String, EcoPoint> _points = {};
  Timer? _moveDebounce;
  _AreaRequest? _pendingRequest;
  bool _initialized = false;
  bool _isSearching = false;
  bool _isLocating = false;
  String _status = 'Abra o mapa para localizar os EcoPontos próximos.';
  String _searchText = '';
  String _lastAreaKey = '';
  LatLng? _userLocation;
  LatLng _lastMapCenter = const LatLng(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );
  double _lastMapZoom = 13;
  EcoPointCategory? _categoryFilter;
  MapTileStyle _tileStyle = MapTileStyle.dark;

  bool get isSearching => _isSearching;
  bool get isLocating => _isLocating;
  bool get isBusy => _isSearching || _isLocating;
  String get status => _status;
  LatLng? get userLocation => _userLocation;
  MapTileStyle get tileStyle => _tileStyle;
  EcoPointCategory? get categoryFilter => _categoryFilter;
  int get totalCount => _points.length;

  List<EcoPoint> get allPoints {
    final items = _points.values.toList();
    items.sort(
      (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      ),
    );
    return items;
  }

  List<EcoPoint> get filteredPoints {
    final query = _searchText.trim().toLowerCase();
    return allPoints
        .where((point) {
          if (_categoryFilter != null && point.category != _categoryFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return '${point.name} ${point.type}'.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final cached = await _store.loadCachedEcoPoints();
    _merge(cached, _lastMapCenter);
    if (cached.isNotEmpty) {
      _status =
          '${cached.length} EcoPontos recentes carregados. Atualizando sua localização…';
      notifyListeners();
    }
    await locateAndSearch();
  }

  Future<void> locateAndSearch() async {
    if (_isLocating) return;
    _isLocating = true;
    _status = 'Obtendo sua localização…';
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationMessage(
          'Ative a localização do celular para encontrar EcoPontos próximos.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const _LocationMessage(
          'A localização foi negada. Você ainda pode mover o mapa e buscar outra área.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _LocationMessage(
          'Permita a localização nas configurações do celular.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _userLocation = LatLng(position.latitude, position.longitude);
      _lastMapCenter = _userLocation!;
      notifyListeners();
      await searchArea(
        _userLocation!,
        zoom: 15,
        radiusOverride: 5000,
        force: true,
      );
    } on _LocationMessage catch (error) {
      _status = error.message;
    } catch (_) {
      _status = 'Não foi possível obter sua localização. Mova o mapa para pesquisar manualmente.';
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  void onMapMoved(LatLng center, double zoom) {
    _lastMapCenter = center;
    _lastMapZoom = zoom;
    _moveDebounce?.cancel();
    _moveDebounce = Timer(AppConfig.mapSearchDelay, () {
      unawaited(searchArea(center, zoom: zoom));
    });
  }

  Future<void> refreshVisibleArea() {
    return searchArea(_lastMapCenter, zoom: _lastMapZoom, force: true);
  }

  Future<void> searchArea(
    LatLng center, {
    required double zoom,
    int? radiusOverride,
    bool force = false,
  }) async {
    final radius = radiusOverride ?? radiusForZoom(zoom);
    final request = _AreaRequest(
      center: center,
      zoom: zoom,
      radius: radius,
      force: force,
    );
    if (_isSearching) {
      _pendingRequest = request;
      return;
    }
    final areaKey =
        '${center.latitude.toStringAsFixed(3)}|${center.longitude.toStringAsFixed(3)}|${radius ~/ 500}';
    if (!force && areaKey == _lastAreaKey) return;
    _lastAreaKey = areaKey;
    _isSearching = true;
    _status = 'Buscando todos os EcoPontos mapeados nesta área…';
    notifyListeners();

    final beforeCount = _points.length;
    final origin = _userLocation ?? center;
    final gathered = <EcoPoint>[];

    Future<List<EcoPoint>> collect(Future<List<EcoPoint>> operation) async {
      try {
        final items = await operation;
        if (items.isNotEmpty) {
          gathered.addAll(items);
          _merge(items, origin);
          _status =
              '${_points.length} EcoPontos carregados. Ampliando os resultados…';
          notifyListeners();
        }
        return items;
      } catch (_) {
        return const [];
      }
    }

    try {
      final quick = collect(_service.searchQuick(center, radius));
      final detailed = collect(_service.searchDetailed(center, radius));
      await Future.wait([quick, detailed]);
      if (gathered.isEmpty) {
        await collect(
          _service.searchQuick(
            center,
            radius,
            queries: const ['reciclagem', 'ponto de descarte'],
          ),
        );
      }
      final addedCount = _points.length - beforeCount;
      if (_points.isEmpty) {
        _status = 'Nenhum EcoPonto mapeado foi encontrado nesta área.';
      } else if (addedCount > 0) {
        _status =
            '${_points.length} EcoPontos no mapa — $addedCount ${addedCount == 1 ? 'novo ponto' : 'novos pontos'} nesta área.';
      } else {
        _status =
            '${_points.length} EcoPontos mantidos. Nenhum novo ponto nesta área.';
      }
      await _store.saveEcoPoints(allPoints);
    } catch (_) {
      _lastAreaKey = '';
      _status = _points.isEmpty
          ? 'Não foi possível carregar os EcoPontos agora.'
          : '${_points.length} EcoPontos anteriores continuam no mapa.';
    } finally {
      _isSearching = false;
      notifyListeners();
      final pending = _pendingRequest;
      _pendingRequest = null;
      if (pending != null) {
        unawaited(
          searchArea(
            pending.center,
            zoom: pending.zoom,
            radiusOverride: pending.radius,
            force: pending.force,
          ),
        );
      }
    }
  }

  void setSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  void setCategoryFilter(EcoPointCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setTileStyle(MapTileStyle style) {
    _tileStyle = style;
    notifyListeners();
  }

  void _merge(Iterable<EcoPoint> incoming, LatLng origin) {
    for (final point in incoming) {
      _points[point.coordinateKey] = point.withDistanceFrom(origin);
    }
  }

  static int radiusForZoom(double zoom) {
    final calculated = 2500 * math.pow(2, 15 - zoom);
    return calculated
        .round()
        .clamp(2500, AppConfig.maxMapSearchRadiusMeters)
        .toInt();
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    super.dispose();
  }
}

class _AreaRequest {
  const _AreaRequest({
    required this.center,
    required this.zoom,
    required this.radius,
    required this.force,
  });

  final LatLng center;
  final double zoom;
  final int radius;
  final bool force;
}

class _LocationMessage implements Exception {
  const _LocationMessage(this.message);

  final String message;
}
