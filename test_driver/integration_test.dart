import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final outputPath = Platform.environment['LOCUS_SCREENSHOT_DIR'];
  if (outputPath == null || outputPath.isEmpty) {
    throw StateError('LOCUS_SCREENSHOT_DIR is required.');
  }
  final output = Directory(outputPath)..createSync(recursive: true);

  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? _,
        ]) async {
          final image = File(p.join(output.path, '$screenshotName.png'));
          image.writeAsBytesSync(screenshotBytes, flush: true);
          return screenshotBytes.isNotEmpty;
        },
    writeResponseOnFailure: true,
  );
}
