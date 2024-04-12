import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('text direction', () {
    testWidgets(
        '''no text direction items will be displayed in the default/LTR mode, and three text direction items will be displayed when toggle is enabled.''',
        (tester) async {
      // combine the two tests into one to avoid the time-consuming process of initializing the app
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final selection = Selection.single(
        path: [0],
        startOffset: 0,
        endOffset: 1,
      );
      // click the first line of the readme
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.updateSelection(selection);
      await tester.pumpAndSettle();

      // because this icons are defined in the appflowy_editor package, we can't fetch the icons by SVG data. [textDirectionItems]
      final textDirectionIconNames = [
        'toolbar/text_direction_auto',
        'toolbar/text_direction_ltr',
        'toolbar/text_direction_rtl',
      ];
      // no text direction items by default
      var button = find.byWidgetPredicate(
        (widget) =>
            widget is SVGIconItemWidget &&
            textDirectionIconNames.contains(widget.iconName),
      );
      expect(button, findsNothing);

      // switch to the RTL mode
      await tester.toggleEnableRTLToolbarItems();

      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.updateSelection(selection);
      await tester.pumpAndSettle();

      button = find.byWidgetPredicate(
        (widget) =>
            widget is SVGIconItemWidget &&
            textDirectionIconNames.contains(widget.iconName),
      );
      expect(button, findsNWidgets(3));
    });
  });
}
