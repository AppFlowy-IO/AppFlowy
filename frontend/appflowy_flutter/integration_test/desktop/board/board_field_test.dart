import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
        fieldName,
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
  });
}
