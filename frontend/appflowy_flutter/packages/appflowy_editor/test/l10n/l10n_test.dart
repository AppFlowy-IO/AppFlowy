import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('l10n.dart', () {
    for (final locale
        in AppFlowyEditorLocalizations.delegate.supportedLocales) {
      testWidgets('test localization', (tester) async {
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting(locale: locale);
      });
    }
  });
}
