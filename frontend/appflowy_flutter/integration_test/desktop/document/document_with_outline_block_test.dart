import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/outline/outline_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

const String heading1 = "Heading 1";
const String heading2 = "Heading 2";
const String heading3 = "Heading 3";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('outline block test', () {
    testWidgets('insert an outline block', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'outline_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertOutlineInDocument(tester);

      // validate the outline is inserted
      expect(find.byType(OutlineBlockWidget), findsOneWidget);
    });

    testWidgets('insert an outline block and check if headings are visible',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'outline_test',
      );

      await insertHeadingComponent(tester);
      /* Results in:
      * # Heading 1
      * ## Heading 2
      * ### Heading 3
      */

      await tester.editor.tapLineOfEditorAt(3);
      await insertOutlineInDocument(tester);

      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading1),
        ),
        findsOneWidget,
      );

      // Heading 2 is prefixed with a bullet
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading2),
        ),
        findsOneWidget,
      );

      // Heading 3 is prefixed with a dash
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading3),
        ),
        findsOneWidget,
      );

      // update the Heading 1 to Heading 1Hello world
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('Hello world');
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text('${heading1}Hello world'),
        ),
        findsOneWidget,
      );
    });

    testWidgets("control the depth of outline block", (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'outline_test',
      );

      await insertHeadingComponent(tester);
      /* Results in:
        * # Heading 1
        * ## Heading 2
        * ### Heading 3
      */

      await tester.editor.tapLineOfEditorAt(3);
      await insertOutlineInDocument(tester);

      // expect to find only the `heading1` widget under the [OutlineBlockWidget]
      await hoverAndClickDepthOptionAction(tester, [3], 1);
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading2),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading3),
        ),
        findsNothing,
      );
      //////

      /// expect to find only the 'heading1' and 'heading2' under the [OutlineBlockWidget]
      await hoverAndClickDepthOptionAction(tester, [3], 2);
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading3),
        ),
        findsNothing,
      );
      //////

      // expect to find all the headings under the [OutlineBlockWidget]
      await hoverAndClickDepthOptionAction(tester, [3], 3);
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading1),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading2),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text(heading3),
        ),
        findsOneWidget,
      );
      //////
    });
  });
}

/// Inserts an outline block in the document
Future<void> insertOutlineInDocument(WidgetTester tester) async {
  // open the actions menu and insert the outline block
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_selectionMenu_outline.tr(),
  );
  await tester.pumpAndSettle();
}

Future<void> hoverAndClickDepthOptionAction(
  WidgetTester tester,
  List<int> path,
  int level,
) async {
  await tester.editor.hoverAndClickOptionMenuButton([3]);
  await tester.tap(find.byType(AppFlowyPopover).hitTestable().last);
  await tester.pumpAndSettle();

  // Find a total of 4 HoverButtons under the [BlockOptionButton],
  // in addition to 3 HoverButtons under the [DepthOptionAction] - (child of BlockOptionButton)
  await tester.tap(find.byType(HoverButton).hitTestable().at(3 + level));
  await tester.pumpAndSettle();
}

Future<void> insertHeadingComponent(WidgetTester tester) async {
  await tester.editor.tapLineOfEditorAt(0);
  await tester.ime.insertText('# $heading1\n');
  await tester.ime.insertText('## $heading2\n');
  await tester.ime.insertText('### $heading3\n');
}
