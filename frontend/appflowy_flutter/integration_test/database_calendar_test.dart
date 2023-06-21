import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database', () {
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

    testWidgets('update calendar layout', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // open setting
      await tester.tapDatabaseSettingButton();
      await tester.tapDatabaseLayoutButton();
      await tester.selectDatabaseLayoutType(DatabaseLayoutPB.Board);
      await tester.assertCurrentDatabaseLayoutType(DatabaseLayoutPB.Board);

      await tester.tapDatabaseSettingButton();
      await tester.tapDatabaseLayoutButton();
      await tester.selectDatabaseLayoutType(DatabaseLayoutPB.Grid);
      await tester.assertCurrentDatabaseLayoutType(DatabaseLayoutPB.Grid);

      await tester.pumpAndSettle();
    });

    testWidgets('calendar start from day setting', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create calendar view
      await tester.createNewPageWithName(ViewLayoutPB.Calendar, 'calendar');

      // Open setting
      await tester.tapDatabaseSettingButton();
      await tester.tapCalendarLayoutSettingButton();

      // select the first day of week is Monday
      await tester.tapFirstDayOfWeek();
      await tester.tapFirstDayOfWeekStartFromMonday();

      // Open the other page and open the new calendar page again
      await tester.openPage(readme);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await tester.openPage('calendar');

      // Open setting again and check the start from Monday is selected
      await tester.tapDatabaseSettingButton();
      await tester.tapCalendarLayoutSettingButton();
      await tester.tapFirstDayOfWeek();
      tester.assertFirstDayOfWeekStartFromMonday();

      await tester.pumpAndSettle();
    });
  });
}
