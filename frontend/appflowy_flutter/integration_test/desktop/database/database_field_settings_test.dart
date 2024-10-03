import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid field settings test:', () {
    testWidgets('field visibility', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Grid);

      // create a field
      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('New field 1');
      await tester.dismissFieldEditor();

      // hide the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapHidePropertyButton();
      tester.noFieldWithName('New field 1');

      // go back to inline database view, expect field to be shown
      await tester.tapTabBarLinkedViewByViewName('Untitled');
      tester.findFieldWithName('New field 1');

      // go back to linked database view, expect field to be hidden
      await tester.tapTabBarLinkedViewByViewName('Grid');
      tester.noFieldWithName('New field 1');

      // use the settings button to show the field
      await tester.tapDatabaseSettingButton();
      await tester.tapViewPropertiesButton();
      await tester.tapViewTogglePropertyVisibilityButtonByName('New field 1');
      await tester.dismissFieldEditor();
      tester.findFieldWithName('New field 1');

      // open first row in popup then hide the field
      await tester.openFirstRowDetailPage();
      await tester.tapGridFieldWithNameInRowDetailPage('New field 1');
      await tester.tapHidePropertyButtonInFieldEditor();
      await tester.dismissRowDetailPage();
      tester.noFieldWithName('New field 1');

      // the field should still be sort and filter-able
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.RichText,
        "New field 1",
      );
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.RichText, "New field 1");
    });
  });
}
