import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/widgets/rename_view_popover.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Rename current view item', () {
    testWidgets('by F2 shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await FlowyTestKeyboard.simulateKeyDownEvent(
        [LogicalKeyboardKey.f2],
        tester: tester,
      );
      await tester.pumpAndSettle();

      expect(find.byType(RenameViewPopover), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(RenameViewPopover),
          matching: find.byType(FlowyTextField),
        ),
        'hello',
      );
      await tester.pumpAndSettle();

      // Dismiss rename popover
      await tester.tap(find.byType(AppFlowyEditor));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SingleInnerViewItem),
          matching: find.text('hello'),
        ),
        findsOneWidget,
      );
    });
  });
}
