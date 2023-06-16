import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid page', () {
    const location = 'appflowy';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('rename existing field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Invoke the field editor
      await tester.tapGridFieldWithName('Name');
      await tester.tapEditPropertyButton();

      await tester.renameField('hello world');
      await tester.dismissFieldEditor();

      await tester.tapGridFieldWithName('hello world');
      await tester.pumpAndSettle();
    });

    testWidgets('update field type of existing field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditPropertyButton();

      await tester.tapTypeOptionButton();
      await tester.selectFieldType(FieldType.Checkbox);
      await tester.dismissFieldEditor();

      await tester.assertFieldTypeWithFieldName(
        'Type',
        FieldType.Checkbox,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('create a field and rename it', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // create a field
      await tester.createField(FieldType.Checklist, 'checklist');

      // check the field is created successfully
      await tester.findFieldWithName('checklist');
      await tester.pumpAndSettle();
    });

    testWidgets('delete field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // create a field
      await tester.createField(FieldType.Checkbox, 'New field 1');

      // Delete the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapDeletePropertyButton();

      // confirm delete
      await tester.tapDialogOkButton();

      await tester.noFieldWithName('New field 1');
      await tester.pumpAndSettle();
    });

    testWidgets('duplicate field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // create a field
      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('New field 1');
      await tester.dismissFieldEditor();

      // Delete the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapDuplicatePropertyButton();

      await tester.findFieldWithName('New field 1 (copy)');
      await tester.pumpAndSettle();
    });

    testWidgets('hide field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // create a field
      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('New field 1');
      await tester.dismissFieldEditor();

      // Delete the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapHidePropertyButton();

      await tester.noFieldWithName('New field 1');
      await tester.pumpAndSettle();
    });

    testWidgets('create checklist field ', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();

      // Open the type option menu
      await tester.tapTypeOptionButton();

      await tester.selectFieldType(FieldType.Checklist);

      // After update the field type, the cells should be updated
      await tester.findCellByFieldType(FieldType.Checklist);

      await tester.pumpAndSettle();
    });

    testWidgets('create list of fields', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      for (final fieldType in [
        FieldType.Checklist,
        FieldType.DateTime,
        FieldType.Number,
        FieldType.URL,
        FieldType.MultiSelect,
        FieldType.LastEditedTime,
        FieldType.CreatedTime,
        FieldType.Checkbox,
      ]) {
        await tester.scrollToRight(find.byType(GridPage));
        await tester.tapNewPropertyButton();
        await tester.renameField(fieldType.name);

        // Open the type option menu
        await tester.tapTypeOptionButton();

        await tester.selectFieldType(fieldType);
        await tester.dismissFieldEditor();

        // After update the field type, the cells should be updated
        await tester.findCellByFieldType(fieldType);
        await tester.pumpAndSettle();
      }
    });
  });
}
