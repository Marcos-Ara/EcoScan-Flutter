abstract final class AppConfig {
  static const appName = 'EcoScan AI';
  static const packageName = 'br.com.ecoscan.ecoscan_mobile';
  static const defaultLatitude = -23.5505;
  static const defaultLongitude = -46.6333;
  static const maxMapSearchRadiusMeters = 25000;
  static const requestTimeout = Duration(seconds: 9);

  static const overpassEndpoints = <String>[
    // Community endpoints are queried sequentially, never in parallel.
    'https://overpass.private.coffee/api/interpreter',
    'https://overpass-api.de/api/interpreter',
  ];
}
