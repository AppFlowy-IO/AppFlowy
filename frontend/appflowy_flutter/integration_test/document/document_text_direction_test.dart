import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('text direction', () {
    testWidgets(
        '''no text direction items will be displayed in the default/LTR mode,and three text direction items will be displayed in the RTL mode.''',
        (tester) async {
      // combine the two tests into one to avoid the time-consuming process of initializing the app
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

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
        'toolbar/text_direction_left',
        'toolbar/text_direction_right',
      ];
      // no text direction items in default/LTR mode
      var button = find.byWidgetPredicate(
        (widget) =>
            widget is SVGIconItemWidget &&
            textDirectionIconNames.contains(widget.iconName),
      );
      expect(button, findsNothing);

      // switch to the RTL mode
      await tester.switchLayoutDirectionMode(LayoutDirection.rtlLayout);

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
