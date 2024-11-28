import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

const String heading1 = "Heading 1";
const String heading2 = "Heading 2";
const String heading3 = "Heading 3";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('simple table block test:', () {
    testWidgets('insert a simple table block', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertTableInDocument(tester);

      // validate the table is inserted
      expect(find.byType(SimpleTableBlockWidget), findsOneWidget);
    });
  });
}

/// Insert a table in the document
Future<void> insertTableInDocument(WidgetTester tester) async {
  // open the actions menu and insert the outline block
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_slashMenu_name_table.tr(),
  );
  await tester.pumpAndSettle();
}
