import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/app_config.dart';
import '../models/eco_point.dart';

/// Loads EcoPoints without coupling the map widget to a network provider.
///
/// The map base layer is independent from place search. EcoPoints come from
/// OpenStreetMap/Overpass with a small sequential query and a Nominatim fallback.
/// Results are cached so moving between tabs does not repeatedly hit community
/// services. A provider outage never removes markers already loaded.
class EcoPointService {
  EcoPointService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, _CacheEntry> _cache = {};
  DateTime _lastNominatimRequest = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastDetailedRequest = DateTime.fromMillisecondsSinceEpoch(0);

  Future<List<EcoPoint>> searchQuick(
    LatLng center,
    int radius, {
    List<String> queries = const ['ecoponto'],
  }) async {
    final safeRadius = radius
        .clamp(2500, AppConfig.maxMapSearchRadiusMeters)
        .toInt();
    final cacheKey = _cacheKey('quick:${queries.join('|')}', center, safeRadius);
    final cached = _readCache(cacheKey);
    if (cached != null) return cached;

    final latitudeDelta = safeRadius / 111320;
    final cosine = math
        .cos(center.latitude * math.pi / 180)
        .abs()
        .clamp(0.25, 1.0);
    final longitudeDelta = safeRadius / (111320 * cosine);
    final found = <EcoPoint>[];

    // Nominatim asks clients to avoid bursts. Queries are serialized and only
    // the fallback query is attempted when the previous one returned nothing.
    for (var index = 0; index < queries.length; index++) {
      final query = queries[index].trim();
      if (query.isEmpty) continue;
      if (index > 0 && found.isNotEmpty) break;
      await _respectNominatimInterval();
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'format': 'jsonv2',
          'limit': '25',
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
        _lastNominatimRequest = DateTime.now();
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
      } on TimeoutException {
        // Keep cached/previous markers and let the UI offer a manual refresh.
      } catch (_) {
        // Network lookup is best-effort; the map itself remains usable.
      }
    }

    final result = _deduplicate(found);
    _writeCache(cacheKey, result);
    return result;
  }

  Future<List<EcoPoint>> searchDetailed(LatLng center, int radius) async {
    // Public Overpass instances are shared infrastructure. A smaller search
    // radius dramatically reduces timeouts while still covering a useful area
    // around the user. Wider map views can be refreshed area-by-area.
    final safeRadius = radius.clamp(1500, 7000).toInt();
    final cacheKey = _cacheKey('detailed', center, safeRadius);
    final cached = _readCache(cacheKey);
    if (cached != null) return cached;
    final elapsed = DateTime.now().difference(_lastDetailedRequest);
    const interval = Duration(seconds: 4);
    if (elapsed < interval) await Future<void>.delayed(interval - elapsed);

    final query =
        '''[out:json][timeout:7];
      (
        nwr(around:$safeRadius,${center.latitude},${center.longitude})[amenity=recycling];
        nwr(around:$safeRadius,${center.latitude},${center.longitude})[amenity=waste_disposal];
        nwr(around:$safeRadius,${center.latitude},${center.longitude})[amenity=waste_transfer_station];
        nwr(around:$safeRadius,${center.latitude},${center.longitude})[recycling_type=centre];
      );
      out center tags;''';

    // Sequential fallback: do not hit every public mirror at the same time.
    for (final endpoint in AppConfig.overpassEndpoints) {
      try {
        _lastDetailedRequest = DateTime.now();
        final items = await _queryOverpass(endpoint, query);
        _writeCache(cacheKey, items);
        return items;
      } catch (_) {
        // Try the next mirror.
      }
    }
    throw const FormatException('Serviço de EcoPontos temporariamente indisponível.');
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
      throw const FormatException('Falha na consulta dos EcoPontos.');
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

  Future<void> _respectNominatimInterval() async {
    final elapsed = DateTime.now().difference(_lastNominatimRequest);
    const minimum = Duration(milliseconds: 1100);
    if (elapsed < minimum) await Future<void>.delayed(minimum - elapsed);
  }

  List<EcoPoint>? _readCache(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.createdAt) > const Duration(minutes: 60)) {
      _cache.remove(key);
      return null;
    }
    return entry.points;
  }

  void _writeCache(String key, List<EcoPoint> points) {
    _cache[key] = _CacheEntry(DateTime.now(), List.unmodifiable(points));
  }

  static String _cacheKey(String prefix, LatLng center, int radius) =>
      '$prefix:${center.latitude.toStringAsFixed(3)}:'
      '${center.longitude.toStringAsFixed(3)}:${radius ~/ 500}';

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

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Accept-Language': 'pt-BR',
    if (!kIsWeb)
      'User-Agent': 'EcoScanMobile/2.0 (br.com.ecoscan.ecoscan_mobile)',
  };

  void dispose() => _client.close();
}

class _CacheEntry {
  const _CacheEntry(this.createdAt, this.points);
  final DateTime createdAt;
  final List<EcoPoint> points;
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
