import 'package:appflowy_editor/src/extensions/url_launcher_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // test('safeLaunchUrl with scheme', () async {
  //   const href = 'https://github.com/AppFlowy-IO';
  //   final result = await safeLaunchUrl(href);
  //   expect(result, true);
  // });

  // test('safeLaunchUrl without scheme', () async {
  //   const href = 'github.com/AppFlowy-IO';
  //   final result = await safeLaunchUrl(href);
  //   expect(result, true);
  // });

  test('safeLaunchUrl without scheme', () async {
    const href = null;
    final result = await safeLaunchUrl(href);
    expect(result, false);
  });
}
