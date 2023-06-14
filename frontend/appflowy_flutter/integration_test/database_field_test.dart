import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid', () {
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

    testWidgets('rename field of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('checklist');

      // Check the field is created successfully
      await tester.findFieldWithName('checklist');
      await tester.pumpAndSettle();
    });

    testWidgets('create checklist field of the grid', (tester) async {
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

    testWidgets('create list of fields of the grid', (tester) async {
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
        await tester.findCellByFieldType(FieldType.Checklist);
        await tester.pumpAndSettle();
      }
    });
  });
}
