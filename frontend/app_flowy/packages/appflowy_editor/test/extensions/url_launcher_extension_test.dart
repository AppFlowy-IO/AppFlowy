import 'package:appflowy_editor/src/extensions/url_launcher_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safeLaunchUrl without scheme', () async {
    const href = null;
    final result = await safeLaunchUrl(href);
    expect(result, false);
  });
}
