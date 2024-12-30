import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid filter:', () {
    testWidgets('add text filter', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.RichText, 'Name');
      await tester.tapFilterButtonInGrid('Name');

      // enter 'A' in the filter text field
      tester.assertNumberOfRowsInGridPage(10);
      await tester.enterTextInTextFilter('A');
      tester.assertNumberOfRowsInGridPage(1);

      // after remove the filter, the grid should show all rows
      await tester.enterTextInTextFilter('');
      tester.assertNumberOfRowsInGridPage(10);

      await tester.enterTextInTextFilter('B');
      tester.assertNumberOfRowsInGridPage(1);

      // open the menu to delete the filter
      await tester.tapDisclosureButtonInFinder(find.byType(TextFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();
      tester.assertNumberOfRowsInGridPage(10);

      await tester.pumpAndSettle();
    });

    testWidgets('add checkbox filter', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.Checkbox, 'Done');
      tester.assertNumberOfRowsInGridPage(5);

      await tester.tapFilterButtonInGrid('Done');
      await tester.tapCheckboxFilterButtonInGrid();

      await tester.tapUnCheckedButtonOnCheckboxFilter();
      tester.assertNumberOfRowsInGridPage(5);

      await tester
          .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();
      tester.assertNumberOfRowsInGridPage(10);

      await tester.pumpAndSettle();
    });

    testWidgets('add checklist filter', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.Checklist, 'checklist');

      // By default, the condition of checklist filter is 'uncompleted'
      tester.assertNumberOfRowsInGridPage(9);

      await tester.tapFilterButtonInGrid('checklist');
      await tester.tapChecklistFilterButtonInGrid();

      await tester.tapCompletedButtonOnChecklistFilter();
      tester.assertNumberOfRowsInGridPage(1);

      await tester.pumpAndSettle();
    });

    testWidgets('add single select filter', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.SingleSelect, 'Type');

      await tester.tapFilterButtonInGrid('Type');

      // select the option 's6'
      await tester.tapOptionFilterWithName('s6');
      tester.assertNumberOfRowsInGridPage(0);

      // unselect the option 's6'
      await tester.tapOptionFilterWithName('s6');
      tester.assertNumberOfRowsInGridPage(10);

      // select the option 's5'
      await tester.tapOptionFilterWithName('s5');
      tester.assertNumberOfRowsInGridPage(1);

      // select the option 's4'
      await tester.tapOptionFilterWithName('s4');

      // The row with 's4' should be shown.
      tester.assertNumberOfRowsInGridPage(2);

      await tester.pumpAndSettle();
    });

    testWidgets('add multi select filter', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.MultiSelect,
        'multi-select',
      );

      await tester.tapFilterButtonInGrid('multi-select');
      await tester.scrollOptionFilterListByOffset(const Offset(0, -200));

      // select the option 'm1'. Any option with 'm1' should be shown.
      await tester.tapOptionFilterWithName('m1');
      tester.assertNumberOfRowsInGridPage(5);
      await tester.tapOptionFilterWithName('m1');

      // select the option 'm2'. Any option with 'm2' should be shown.
      await tester.tapOptionFilterWithName('m2');
      tester.assertNumberOfRowsInGridPage(4);
      await tester.tapOptionFilterWithName('m2');

      // select the option 'm4'. Any option with 'm4' should be shown.
      await tester.tapOptionFilterWithName('m4');
      tester.assertNumberOfRowsInGridPage(1);

      await tester.pumpAndSettle();
    });

    testWidgets('add date filter', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.DateTime, 'date');

      // By default, the condition of date filter is current day and time
      tester.assertNumberOfRowsInGridPage(0);

      await tester.tapFilterButtonInGrid('date');
      await tester.changeDateFilterCondition(DateTimeFilterCondition.before);
      tester.assertNumberOfRowsInGridPage(7);

      await tester.changeDateFilterCondition(DateTimeFilterCondition.isEmpty);
      tester.assertNumberOfRowsInGridPage(3);

      await tester.pumpAndSettle();
    });

    testWidgets('add timestamp filter', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.createField(
        FieldType.CreatedTime,
        name: 'Created at',
      );

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.CreatedTime,
        'Created at',
      );
      await tester.pumpAndSettle();

      tester.assertNumberOfRowsInGridPage(3);

      await tester.tapFilterButtonInGrid('Created at');
      await tester.changeDateFilterCondition(DateTimeFilterCondition.before);
      tester.assertNumberOfRowsInGridPage(0);

      await tester.pumpAndSettle();
    });

    testWidgets('create new row when filters don\'t autofill', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.RichText,
        'Name',
      );
      tester.assertNumberOfRowsInGridPage(3);

      await tester.tapCreateRowButtonInGrid();
      tester.assertNumberOfRowsInGridPage(4);

      await tester.tapFilterButtonInGrid('Name');
      await tester
          .changeTextFilterCondition(TextFilterConditionPB.TextIsNotEmpty);
      await tester.dismissCellEditor();
      tester.assertNumberOfRowsInGridPage(0);

      await tester.tapCreateRowButtonInGrid();
      tester.assertNumberOfRowsInGridPage(0);
      expect(find.byType(RowDetailPage), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
