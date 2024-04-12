import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Grid Calculations', () {
    testWidgets('add calculation and update cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Change one Field to Number
      await tester.changeFieldTypeOfFieldWithName('Type', FieldType.Number);

      expect(find.text('Calculate'), findsOneWidget);

      await tester.changeCalculateAtIndex(1, CalculationType.Sum);

      // Enter values in cells
      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.Number,
        input: '100',
      );

      await tester.editCell(
        rowIndex: 1,
        fieldType: FieldType.Number,
        input: '100',
      );

      // Dismiss edit cell
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('add calculations and remove row', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Change two Fields to Number
      await tester.changeFieldTypeOfFieldWithName('Type', FieldType.Number);
      await tester.changeFieldTypeOfFieldWithName('Done', FieldType.Number);

      expect(find.text('Calculate'), findsNWidgets(2));

      await tester.changeCalculateAtIndex(1, CalculationType.Sum);
      await tester.changeCalculateAtIndex(2, CalculationType.Min);

      // Enter values in cells
      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.Number,
        input: '100',
      );
      await tester.editCell(
        rowIndex: 1,
        fieldType: FieldType.Number,
        input: '150',
      );
      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.Number,
        input: '50',
        cellIndex: 1,
      );
      await tester.editCell(
        rowIndex: 1,
        fieldType: FieldType.Number,
        input: '100',
        cellIndex: 1,
      );

      await tester.pumpAndSettle();

      // Dismiss edit cell
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('250'), findsOneWidget);
      expect(find.text('50'), findsNWidgets(2));

      // Delete 1st row
      await tester.hoverOnFirstRowOfGrid();
      await tester.tapRowMenuButtonInGrid();
      await tester.tapDeleteOnRowMenu();

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('150'), findsNWidgets(2));
      expect(find.text('100'), findsNWidgets(2));
    });
  });
}
