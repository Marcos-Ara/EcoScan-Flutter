import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/app_config.dart';
import '../models/eco_point.dart';

class EcoPointService {
  EcoPointService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<EcoPoint>> searchQuick(
    LatLng center,
    int radius, {
    List<String> queries = const ['ecoponto'],
  }) async {
    final safeRadius = radius.clamp(2500, AppConfig.maxMapSearchRadiusMeters);
    final latitudeDelta = safeRadius / 111320;
    final cosine = math
        .cos(center.latitude * math.pi / 180)
        .abs()
        .clamp(0.25, 1.0);
    final longitudeDelta = safeRadius / (111320 * cosine);
    final found = <EcoPoint>[];

    for (final query in queries) {
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'format': 'jsonv2',
          'limit': '30',
          'accept-language': 'pt-BR',
          'q': query,
          'viewbox': [
            center.longitude - longitudeDelta,
            center.latitude + latitudeDelta,
            center.longitude + longitudeDelta,
            center.latitude - latitudeDelta,
          ].map((value) => value.toStringAsFixed(6)).join(','),
          'bounded': '1',
        });
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(AppConfig.requestTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final data = jsonDecode(response.body);
        if (data is! List) continue;
        for (final raw in data.whereType<Map<String, dynamic>>()) {
          final latitude = double.tryParse(raw['lat']?.toString() ?? '');
          final longitude = double.tryParse(raw['lon']?.toString() ?? '');
          if (latitude == null || longitude == null) continue;
          final displayName = raw['display_name']?.toString() ?? '';
          final category = _categoryFromText('$displayName $query');
          found.add(
            EcoPoint(
              id: 'nominatim:${raw['place_id'] ?? '$latitude,$longitude'}',
              name: raw['name']?.toString().trim().isNotEmpty == true
                  ? raw['name'].toString()
                  : (displayName.split(',').firstOrNull ?? 'EcoPonto'),
              type: category == EcoPointCategory.recycling
                  ? 'EcoPonto / reciclagem'
                  : 'Local para descarte',
              category: category,
              latitude: latitude,
              longitude: longitude,
            ),
          );
        }
      } catch (_) {
        // A busca detalhada do Overpass continua mesmo se a busca rápida falhar.
      }
    }
    return _deduplicate(found);
  }

  Future<List<EcoPoint>> searchDetailed(LatLng center, int radius) async {
    final safeRadius = radius.clamp(1000, AppConfig.maxMapSearchRadiusMeters);
    final query =
        '''[out:json][timeout:16];(
      node[amenity=recycling](around:$safeRadius,${center.latitude},${center.longitude});
      node[amenity=waste_disposal](around:$safeRadius,${center.latitude},${center.longitude});
      node[amenity=waste_transfer_station](around:$safeRadius,${center.latitude},${center.longitude});
      way[amenity=recycling](around:$safeRadius,${center.latitude},${center.longitude});
      way[amenity=waste_disposal](around:$safeRadius,${center.latitude},${center.longitude});
      way[amenity=waste_transfer_station](around:$safeRadius,${center.latitude},${center.longitude});
      relation[amenity=recycling](around:$safeRadius,${center.latitude},${center.longitude});
      relation[amenity=waste_disposal](around:$safeRadius,${center.latitude},${center.longitude});
      relation[amenity=waste_transfer_station](around:$safeRadius,${center.latitude},${center.longitude});
    );out center tags;''';

    final completer = Completer<List<EcoPoint>>();
    var remaining = AppConfig.overpassEndpoints.length;
    for (final endpoint in AppConfig.overpassEndpoints) {
      _queryOverpass(endpoint, query).then(
        (items) {
          if (items.isNotEmpty && !completer.isCompleted) {
            completer.complete(items);
          }
          remaining -= 1;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(const []);
          }
        },
        onError: (_) {
          remaining -= 1;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(const []);
          }
        },
      );
    }

    return completer.future.timeout(
      const Duration(seconds: 11),
      onTimeout: () => const <EcoPoint>[],
    );
  }

  Future<List<EcoPoint>> _queryOverpass(String endpoint, String query) async {
    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            ..._headers,
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          },
          body: {'data': query},
        )
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    final elements = decoded['elements'];
    if (elements is! List) return const [];
    final points = <EcoPoint>[];

    for (final raw in elements.whereType<Map<String, dynamic>>()) {
      final center = raw['center'];
      final latitude =
          _toDouble(raw['lat']) ??
          (center is Map ? _toDouble(center['lat']) : null);
      final longitude =
          _toDouble(raw['lon']) ??
          (center is Map ? _toDouble(center['lon']) : null);
      if (latitude == null || longitude == null) continue;
      final tags = raw['tags'] is Map<String, dynamic>
          ? raw['tags'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final amenity = tags['amenity']?.toString() ?? '';
      final category = amenity == 'recycling'
          ? EcoPointCategory.recycling
          : EcoPointCategory.disposal;
      final name = (tags['name'] ?? tags['operator'] ?? tags['brand'])
          ?.toString()
          .trim();
      points.add(
        EcoPoint(
          id: '${raw['type'] ?? 'osm'}:${raw['id'] ?? '$latitude,$longitude'}',
          name: name?.isNotEmpty == true
              ? name!
              : (category == EcoPointCategory.recycling
                    ? 'EcoPonto / reciclagem'
                    : 'Ponto de descarte'),
          type: _typeFromTags(tags),
          category: category,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
    return _deduplicate(points);
  }

  static List<EcoPoint> _deduplicate(Iterable<EcoPoint> items) {
    final unique = <String, EcoPoint>{};
    for (final item in items) {
      unique[item.coordinateKey] = item;
    }
    return unique.values.toList(growable: false);
  }

  static EcoPointCategory _categoryFromText(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('reciclag') || normalized.contains('ecoponto')
        ? EcoPointCategory.recycling
        : EcoPointCategory.disposal;
  }

  static String _typeFromTags(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString();
    if (amenity == 'waste_transfer_station') return 'Estação de resíduos';
    if (amenity == 'waste_disposal') return 'Local para descarte';
    if (tags['recycling_type'] == 'centre') return 'Centro de reciclagem';
    return 'EcoPonto / reciclagem';
  }

  static double? _toDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  static const _headers = {
    'Accept': 'application/json',
    'Accept-Language': 'pt-BR',
    'User-Agent': 'EcoScanMobile/1.0 (br.com.ecoscan.ecoscan_mobile)',
  };

  void dispose() => _client.close();
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
