import 'package:appflowy/plugins/document/presentation/editor_plugins/workspace_overview/overview_block_component.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../document/document_with_outline_block_test.dart';
import '../../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String firstLevelParentViewName = 'Overview Test';

  group("Workspace Overview block test", () {
    testWidgets('workspace folder to overview block test', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.editor.tapLineOfEditorAt(0);
      await insertWorkspaceOverviewInDocument(tester);

      // validate the outline is inserted
      expect(find.byType(OverviewBlockWidget), findsOneWidget);

      await tester.createNewPageWithNameUnderParent(
        name: firstLevelParentViewName,
        layout: ViewLayoutPB.Document,
      );

      // inserting nested view pages inside `firstLevelParentView`
      final names = [1, 2, 3, 4].map((e) => 'Document view $e').toList();
      for (var i = 0; i < names.length; i++) {
        await tester.createNewPageWithNameUnderParent(
          name: names[i],
          parentName: firstLevelParentViewName,
          layout: ViewLayoutPB.Document,
        );
      }

      // inserting views
      final viewNames = [1, 2, 3, 4].map((e) => 'View $e').toList();
      for (var i = 0; i < viewNames.length; i++) {
        await tester.createNewPageWithNameUnderParent(
          name: viewNames[i],
          parentName: gettingStarted,
          layout: ViewLayoutPB.Document,
        );
      }

      await tester.openPage(gettingStarted);

      // Sleep for 5 seconds at the end of the test
      await Future.delayed(const Duration(seconds: 7));
    });
  });
}
