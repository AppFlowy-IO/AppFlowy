import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database', () {
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

    testWidgets('create new calendar event using new button', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create the calendar view
      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // Scroll until today's date cell is visible
      await tester.scrollToToday();

      // Hover over today's calendar cell
      await tester.hoverOnTodayCalendarCell();

      // Tap on create new event button
      await tester.tapAddCalendarEventButton();

      // Make sure that the row details page is opened
      tester.assertRowDetailPageOpened();

      // Dismiss the row details page
      await tester.dismissRowDetailPage();

      // Make sure that the event is inserted in the cell
      tester.assertNumberOfEventsInCalendar(1);

      // Create another event on the same day
      await tester.hoverOnTodayCalendarCell();
      await tester.tapAddCalendarEventButton();
      await tester.dismissRowDetailPage();
      tester.assertNumberOfEventsInCalendar(2);
      tester.assertNumberofEventsOnSpecificDay(2, DateTime.now());
    });

    testWidgets('create new calendar event by double-clicking', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create the calendar view
      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // Scroll until today's date cell is visible
      await tester.scrollToToday();

      // Double click on today's calendar cell to create a new event
      await tester.doubleClickCalendarCell(DateTime.now());

      // Make sure that the row details page is opened
      tester.assertRowDetailPageOpened();

      // Dismiss the row details page
      await tester.dismissRowDetailPage();

      // Make sure that the event is inserted in the cell
      tester.assertNumberOfEventsInCalendar(1);

      // Create another event on the same day
      await tester.doubleClickCalendarCell(DateTime.now());
      await tester.dismissRowDetailPage();
      tester.assertNumberOfEventsInCalendar(2);
      tester.assertNumberofEventsOnSpecificDay(2, DateTime.now());
    });

    testWidgets('duplicate/delete a calendar event', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create the calendar view
      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // Create a new event in today's calendar cell
      await tester.scrollToToday();
      await tester.doubleClickCalendarCell(DateTime.now());

      // Duplicate the event
      await tester.tapRowDetailPageDuplicateRowButton();
      await tester.dismissRowDetailPage();

      // Check that there are 2 events
      tester.assertNumberOfEventsInCalendar(2);

      // Delete an event
      await tester.openCalendarEvent(index: 0);
      await tester.tapRowDetailPageDeleteRowButton();

      // Check that there is 1 event
      tester.assertNumberOfEventsInCalendar(1);
    });

    testWidgets('edit the title of a calendar date event', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create the calendar view
      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // Create a new event in today's calendar cell
      await tester.scrollToToday();
      await tester.doubleClickCalendarCell(DateTime.now());
      await tester.dismissRowDetailPage();

      // Click on the event
      await tester.openCalendarEvent(index: 0);

      // Make sure that the row details page is opened
      tester.assertRowDetailPageOpened();

      // Change the title of the event
      await tester.editTitleInRowDetailPage('hello world');

      // Dismiss the row details page
      await tester.dismissRowDetailPage();

      // Make sure that the event is edited
      tester.assertNumberOfEventsInCalendar(1, title: 'hello world');
    });

    testWidgets(
        'edit the date of the date field being used to layout the calendar',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create the calendar view
      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // Create a new event in today's calendar cell
      final today = DateTime.now();
      await tester.scrollToToday();
      await tester.doubleClickCalendarCell(today);
      await tester.dismissRowDetailPage();

      // Make sure that the event is today
      tester.assertNumberofEventsOnSpecificDay(1, today);

      // Click on the event
      await tester.openCalendarEvent(index: 0);

      // Open the date editor of the event
      await tester.tapDateCellInRowDetailPage();
      await tester.findDateEditor(findsOneWidget);

      // Edit the event's date. To avoid selecting a day outside of the current month, the new date will be one day closer to the middle of the month.
      final newDate = today.day < 15
          ? today.add(const Duration(days: 1))
          : today.subtract(const Duration(days: 1));
      await tester.selectDay(content: newDate.day);
      await tester.dismissCellEditor();

      // Dismiss the row details page
      await tester.dismissRowDetailPage();

      // Make sure that the event is edited
      tester.assertNumberOfEventsInCalendar(1);
      tester.assertNumberofEventsOnSpecificDay(1, newDate);
    });

    testWidgets('reschedule an event by drag-and-drop', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create the calendar view
      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();

      // Create a new event on the first of this month
      final today = DateTime.now();
      final firstOfThisMonth = DateTime(today.year, today.month, 1);
      await tester.doubleClickCalendarCell(firstOfThisMonth);
      await tester.dismissRowDetailPage();

      // Drag and drop the event onto the next week, same day
      await tester.dragDropRescheduleCalendarEvent(firstOfThisMonth);

      // Make sure that the event has been rescheduled to the new date
      tester.assertNumberOfEventsInCalendar(1);
      tester.assertNumberofEventsOnSpecificDay(
        1,
        firstOfThisMonth.add(const Duration(days: 7)),
      );
    });
  });
}
