import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

const String _heading1 = 'Heading 1';
const String _heading2 = 'Heading 2';
const String _heading3 = 'Heading 3';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('toggle heading block test:', () {
    testWidgets('insert toggle heading 1 - 3 block', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'toggle heading block test',
      );

      for (var i = 1; i <= 3; i++) {
        await tester.editor.tapLineOfEditorAt(0);
        await _insertToggleHeadingBlockInDocument(tester, i);
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToggleListBlockComponentWidget &&
                widget.node.attributes[ToggleListBlockKeys.level] == i,
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('insert toggle heading 1 - 3 block by shortcuts',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'toggle heading block test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('# > $_heading1\n');
      await tester.ime.insertText('## > $_heading2\n');
      await tester.ime.insertText('### > $_heading3\n');
      await tester.ime.insertText('> # $_heading1\n');
      await tester.ime.insertText('> ## $_heading2\n');
      await tester.ime.insertText('> ### $_heading3\n');
      await tester.pumpAndSettle();

      expect(
        find.byType(ToggleListBlockComponentWidget),
        findsNWidgets(6),
      );
    });
  });
}

Future<void> _insertToggleHeadingBlockInDocument(
  WidgetTester tester,
  int level,
) async {
  final name = switch (level) {
    1 => LocaleKeys.document_slashMenu_name_toggleHeading1.tr(),
    2 => LocaleKeys.document_slashMenu_name_toggleHeading2.tr(),
    3 => LocaleKeys.document_slashMenu_name_toggleHeading3.tr(),
    _ => throw Exception('Invalid level: $level'),
  };
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    name,
    offset: 100,
  );
  await tester.pumpAndSettle();
}
