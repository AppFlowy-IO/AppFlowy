import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/time.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board field test', () {
    testWidgets('change field type whithin card #5360', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      const name = 'Card 1';
      final card1 = find.text(name);
      await tester.tapButton(card1);

      const fieldName = "test change field";
      await tester.createField(
        FieldType.RichText,
        name: fieldName,
        layout: ViewLayoutPB.Board,
      );
      await tester.tapButton(card1);
      await tester.changeFieldTypeOfFieldWithName(
        fieldName,
        FieldType.Checkbox,
        layout: ViewLayoutPB.Board,
      );
      await tester.hoverOnWidget(find.text('Card 2'));
    });

    testWidgets('time field plain time time-type', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      const name = 'Card 1';
      final card1 = find.text(name);
      await tester.tapButton(card1);

      const fieldName = "Time";
      await tester.createField(
        FieldType.Time,
        name: fieldName,
        layout: ViewLayoutPB.Board,
      );
      await tester.tapButton(card1);

      final editableTimeCell = find.byType(EditableTimeCell);
      expect(editableTimeCell, findsOne);
      await tester.enterText(
        find.descendant(of: editableTimeCell, matching: find.byType(TextField)),
        '31',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final EditableTimeCellState state = tester.state(editableTimeCell);
      expect(state.cellBloc.state.content, '31m');
    });
  });
}
