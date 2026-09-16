abstract final class AppConfig {
  static const appName = 'EcoScan AI';
  static const packageName = 'br.com.ecoscan.ecoscan_mobile';
  static const defaultLatitude = -23.5505;
  static const defaultLongitude = -46.6333;
  static const maxMapSearchRadiusMeters = 25000;
  static const mapSearchDelay = Duration(milliseconds: 700);
  static const requestTimeout = Duration(seconds: 10);

  static const overpassEndpoints = <String>[
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];
}
