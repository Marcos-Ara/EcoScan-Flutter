import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = img.decodePng(
    File('verification/previews/brand.png').readAsBytesSync(),
  )!;
  void save(String path, int size) {
    final output = File(path)..parent.createSync(recursive: true);
    output.writeAsBytesSync(
      img.encodePng(
        img.copyResize(
          source,
          width: size,
          height: size,
          interpolation: img.Interpolation.average,
        ),
      ),
    );
  }

  const densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  for (final entry in densities.entries) {
    save(
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      entry.value,
    );
  }
  final contents = jsonDecode(
    File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json')
        .readAsStringSync(),
  ) as Map;
  for (final entry in contents['images'] as List) {
    final size = double.parse((entry['size'] as String).split('x').first);
    final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
    save(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry['filename']}',
      (size * scale).round(),
    );
  }
  for (final scale in [1, 2, 3]) {
    final suffix = scale == 1 ? '' : '@${scale}x';
    save(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
      168 * scale,
    );
  }
  save('android/app/src/main/res/drawable-nodpi/launch_logo.png', 336);
  stdout.writeln('Ícones e abertura nativa atualizados.');
}
