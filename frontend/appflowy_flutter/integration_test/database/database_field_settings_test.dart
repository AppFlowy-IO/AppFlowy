import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/database_test_op.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database field settings', () {
    testWidgets('field visibility', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Grid);

      // create a field
      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('New field 1');
      await tester.dismissFieldEditor();

      // hide the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapHidePropertyButton();
      await tester.noFieldWithName('New field 1');

      // go back to inline database view, expect field to be shown
      await tester.tapTabBarLinkedViewByViewName('Untitled');
      await tester.findFieldWithName('New field 1');

      // go back to linked database view, expect field to be hidden
      await tester.tapTabBarLinkedViewByViewName('Grid');
      await tester.noFieldWithName('New field 1');

      // use the settings button to show the field
      await tester.tapDatabaseSettingButton();
      await tester.tapViewPropertiesButton();
      await tester.tapViewTogglePropertyVisibilityButtonByName('New field 1');
      await tester.dismissFieldEditor();
      await tester.findFieldWithName('New field 1');

      // open first row in popup then hide the field
      await tester.openFirstRowDetailPage();
      await tester.tapGridFieldWithNameInRowDetailPage('New field 1');
      await tester.tapHidePropertyButtonInFieldEditor();
      await tester.dismissRowDetailPage();
      await tester.noFieldWithName('New field 1');
    });
  });
}
