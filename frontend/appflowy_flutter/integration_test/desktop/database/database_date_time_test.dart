import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('edit grid cell:', () {
    for (var i = 0; i < 50; i++) {
      testWidgets('date time', (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapAnonymousSignInButton();

        await tester.createNewPageWithNameUnderParent(
          layout: ViewLayoutPB.Grid,
        );

        const fieldType = FieldType.DateTime;
        await tester.createField(fieldType);

        // Tap the cell to invoke the field editor
        await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
        await tester.findDateEditor(findsOneWidget);

        // Toggle include time
        await tester.toggleIncludeTime();

        // Dismiss the cell editor
        await tester.dismissCellEditor();

        await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
        await tester.findDateEditor(findsOneWidget);

        // Turn off include time
        await tester.toggleIncludeTime();

        // Select a date
        final now = DateTime.now();
        await tester.selectDay(content: now.day);

        await tester.dismissCellEditor();

        tester.assertCellContent(
          rowIndex: 0,
          fieldType: FieldType.DateTime,
          content: DateFormat('MMM dd, y').format(now),
        );

        await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);

        // Toggle include time
        // When toggling include time, the time value is from the previous existing date time, not the current time
        await tester.toggleIncludeTime();

        await tester.dismissCellEditor();

        tester.assertCellContent(
          rowIndex: 0,
          fieldType: FieldType.DateTime,
          content: DateFormat('MMM dd, y HH:mm').format(now),
        );

        await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
        await tester.findDateEditor(findsOneWidget);

        // Change date format
        await tester.tapChangeDateTimeFormatButton();
        await tester.changeDateFormat();

        await tester.dismissCellEditor();

        tester.assertCellContent(
          rowIndex: 0,
          fieldType: FieldType.DateTime,
          content: DateFormat('dd/MM/y HH:mm').format(now),
        );

        await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
        await tester.findDateEditor(findsOneWidget);

        // Change time format
        await tester.tapChangeDateTimeFormatButton();
        await tester.changeTimeFormat();

        await tester.dismissCellEditor();

        tester.assertCellContent(
          rowIndex: 0,
          fieldType: FieldType.DateTime,
          content: DateFormat('dd/MM/y hh:mm a').format(now),
        );

        await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
        await tester.findDateEditor(findsOneWidget);

        // Clear the date and time
        await tester.clearDate();

        tester.assertCellContent(
          rowIndex: 0,
          fieldType: FieldType.DateTime,
          content: '',
        );

        await tester.pumpAndSettle();
      });
    }
  });
}
