import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database view in document', () {
    const location = 'inline_page';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('insert a inline page - grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await testInsertingInlinePage(tester, ViewLayoutPB.Grid);
    });

    testWidgets('insert a inline page - board', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await testInsertingInlinePage(tester, ViewLayoutPB.Board);
    });

    testWidgets('insert a inline page - calendar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await testInsertingInlinePage(tester, ViewLayoutPB.Calendar);
    });

    testWidgets('insert a inline page - document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await testInsertingInlinePage(tester, ViewLayoutPB.Document);
    });
  });
}

/// Insert a referenced database of [layout] into the document
Future<void> testInsertingInlinePage(
  WidgetTester tester,
  ViewLayoutPB layout,
) async {
  // create a new grid
  final id = uuid();
  final name = '${layout.name}_$id';
  await tester.createNewPageWithName(
    layout,
    name,
  );
  // create a new document
  await tester.createNewPageWithName(
    ViewLayoutPB.Document,
    'insert_a_inline_page_${layout.name}',
  );
  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);
  // insert a referenced grid
  await tester.editor.showAtMenu();
  await tester.editor.tapAtMenuItemWithName(name);

  final mentionBlock = find.byType(MentionBlock);
  expect(mentionBlock, findsOneWidget);

  await tester.tapButton(mentionBlock);
}
