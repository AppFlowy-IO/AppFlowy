import 'package:appflowy/plugins/database/calendar/presentation/calendar_event_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('calendar', () {
    testWidgets('update calendar layout', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(
        layout: ViewLayoutPB.Calendar,
      );

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
      await tester.tapAnonymousSignInButton();

      // Create calendar view
      const name = 'calendar';
      await tester.createNewPageWithNameUnderParent(
        name: name,
        layout: ViewLayoutPB.Calendar,
      );

      // Open setting
      await tester.tapDatabaseSettingButton();
      await tester.tapCalendarLayoutSettingButton();

      // select the first day of week is Monday
      await tester.tapFirstDayOfWeek();
      await tester.tapFirstDayOfWeekStartFromMonday();

      // Open the other page and open the new calendar page again
      await tester.openPage(gettingStarted);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await tester.openPage(name, layout: ViewLayoutPB.Calendar);

      // Open setting again and check the start from Monday is selected
      await tester.tapDatabaseSettingButton();
      await tester.tapCalendarLayoutSettingButton();
      await tester.tapFirstDayOfWeek();
      tester.assertFirstDayOfWeekStartFromMonday();

      await tester.pumpAndSettle();
    });

    testWidgets('creating and editing calendar events', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create the calendar view
      await tester.createNewPageWithNameUnderParent(
        layout: ViewLayoutPB.Calendar,
      );

      // Scroll until today's date cell is visible
      await tester.scrollToToday();

      // Hover over today's calendar cell
      await tester.hoverOnTodayCalendarCell(
        // Tap on create new event button
        onHover: tester.tapAddCalendarEventButton,
      );

      // Make sure that the event editor popup is shown
      tester.assertEventEditorOpen();

      tester.assertNumberOfEventsInCalendar(1);

      // Dismiss the event editor popup
      await tester.dismissEventEditor();

      // Double click on today's calendar cell to create a new event
      await tester.doubleClickCalendarCell(DateTime.now());

      // Make sure that the event is inserted in the cell
      tester.assertNumberOfEventsInCalendar(2);

      // Click on the event
      await tester.openCalendarEvent(index: 0);
      tester.assertEventEditorOpen();

      // Change the title of the event
      await tester.editEventTitle('hello world');
      await tester.dismissEventEditor();

      // Make sure that the event is edited
      tester.assertNumberOfEventsInCalendar(1, title: 'hello world');
      tester.assertNumberOfEventsOnSpecificDay(2, DateTime.now());

      // Click on the event
      await tester.openCalendarEvent(index: 0);
      tester.assertEventEditorOpen();

      // Click on the open icon
      await tester.openEventToRowDetailPage();
      tester.assertRowDetailPageOpened();

      // Duplicate the event
      await tester.tapRowDetailPageRowActionButton();
      await tester.tapRowDetailPageDuplicateRowButton();
      await tester.dismissRowDetailPage();

      // Check that there are 2 events
      tester.assertNumberOfEventsInCalendar(2, title: 'hello world');
      tester.assertNumberOfEventsOnSpecificDay(3, DateTime.now());

      // Delete an event
      await tester.openCalendarEvent(index: 1);
      await tester.deleteEventFromEventEditor();

      // Check that there is 1 event
      tester.assertNumberOfEventsInCalendar(1, title: 'hello world');
      tester.assertNumberOfEventsOnSpecificDay(2, DateTime.now());

      // Delete event from row detail page
      await tester.openCalendarEvent(index: 0);
      await tester.openEventToRowDetailPage();
      tester.assertRowDetailPageOpened();

      await tester.tapRowDetailPageRowActionButton();
      await tester.tapRowDetailPageDeleteRowButton();

      // Check that there is 0 event
      tester.assertNumberOfEventsInCalendar(0, title: 'hello world');
      tester.assertNumberOfEventsOnSpecificDay(1, DateTime.now());
    });

    testWidgets('create and duplicate calendar event', (tester) async {
      const customTitle = "EventTitleCustom";

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create the calendar view
      await tester.createNewPageWithNameUnderParent(
        layout: ViewLayoutPB.Calendar,
      );

      // Scroll until today's date cell is visible
      await tester.scrollToToday();

      // Hover over today's calendar cell
      await tester.hoverOnTodayCalendarCell(
        // Tap on create new event button
        onHover: () async => tester.tapAddCalendarEventButton(),
      );

      // Make sure that the event editor popup is shown
      tester.assertEventEditorOpen();

      tester.assertNumberOfEventsInCalendar(1);

      // Change the title of the event
      await tester.editEventTitle(customTitle);

      // Duplicate event
      final duplicateBtnFinder = find
          .descendant(
            of: find.byType(CalendarEventEditor),
            matching: find.byType(
              FlowyIconButton,
            ),
          )
          .first;
      await tester.tap(duplicateBtnFinder);
      await tester.pumpAndSettle();

      tester.assertNumberOfEventsInCalendar(2, title: customTitle);
    });

    testWidgets('rescheduling events', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create the calendar view
      await tester.createNewPageWithNameUnderParent(
        layout: ViewLayoutPB.Calendar,
      );

      // Create a new event on the first of this month
      final today = DateTime.now();
      final firstOfThisMonth = DateTime(today.year, today.month);
      await tester.doubleClickCalendarCell(firstOfThisMonth);
      await tester.dismissEventEditor();

      // Drag and drop the event onto the next week, same day
      await tester.dragDropRescheduleCalendarEvent();

      // Make sure that the event has been rescheduled to the new date
      final sameDayNextWeek = firstOfThisMonth.add(const Duration(days: 7));
      tester.assertNumberOfEventsInCalendar(1);
      tester.assertNumberOfEventsOnSpecificDay(1, sameDayNextWeek);

      // Delete the event
      await tester.openCalendarEvent(index: 0, date: sameDayNextWeek);
      await tester.deleteEventFromEventEditor();

      // Create another event on the 5th of this month
      final fifthOfThisMonth = DateTime(today.year, today.month, 5);
      await tester.doubleClickCalendarCell(fifthOfThisMonth);
      await tester.dismissEventEditor();

      // Make sure that the event is on the 4t
      tester.assertNumberOfEventsOnSpecificDay(1, fifthOfThisMonth);

      // Click on the event
      await tester.openCalendarEvent(index: 0, date: fifthOfThisMonth);

      // Open the date editor of the event
      await tester.tapDateCellInRowDetailPage();
      await tester.findDateEditor(findsOneWidget);

      // Edit the event's date
      final newDate = fifthOfThisMonth.add(const Duration(days: 1));
      await tester.selectDay(content: newDate.day);
      await tester.dismissCellEditor();

      // Dismiss the event editor
      await tester.dismissEventEditor();

      // Make sure that the event is edited
      tester.assertNumberOfEventsInCalendar(1);
      tester.assertNumberOfEventsOnSpecificDay(1, newDate);

      // Click on the unscheduled events button
      await tester.openUnscheduledEventsPopup();

      // Assert that nothing shows up
      tester.findUnscheduledPopup(findsNothing, 0);

      // Click on the event in the calendar
      await tester.openCalendarEvent(index: 0, date: newDate);

      // Open the date editor of the event
      await tester.tapDateCellInRowDetailPage();
      await tester.findDateEditor(findsOneWidget);

      // Clear the date of the event
      await tester.clearDate();

      // Dismiss the event editor
      await tester.dismissEventEditor();
      tester.assertNumberOfEventsInCalendar(0);

      // Click on the unscheduled events button
      await tester.openUnscheduledEventsPopup();

      // Assert that a popup appears and 1 unscheduled event
      tester.findUnscheduledPopup(findsOneWidget, 1);

      // Click on the unscheduled event
      await tester.clickUnscheduledEvent();

      tester.assertRowDetailPageOpened();
    });

    testWidgets('filter calendar events', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create the calendar view
      await tester.createNewPageWithNameUnderParent(
        layout: ViewLayoutPB.Calendar,
      );

      // Create a new event on the first of this month
      final today = DateTime.now();
      final firstOfThisMonth = DateTime(today.year, today.month);
      await tester.doubleClickCalendarCell(firstOfThisMonth);
      await tester.dismissEventEditor();

      tester.assertNumberOfEventsInCalendar(1);

      await tester.openCalendarEvent(index: 0, date: firstOfThisMonth);
      await tester.tapButton(finderForFieldType(FieldType.MultiSelect));
      await tester.createOption(name: "asdf");
      await tester.createOption(name: "qwer");
      await tester.dismissCellEditor();

      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.MultiSelect, "Tags");

      await tester.tapFilterButtonInGrid('Tags');
      await tester.tapOptionFilterWithName('asdf');
      await tester.dismissCellEditor();

      tester.assertNumberOfEventsInCalendar(1);

      final secondOfThisMonth = DateTime(today.year, today.month, 2);
      await tester.doubleClickCalendarCell(secondOfThisMonth);
      await tester.dismissEventEditor();
      tester.assertNumberOfEventsInCalendar(2);

      await tester.openCalendarEvent(index: 0, date: secondOfThisMonth);
      await tester.tapButton(finderForFieldType(FieldType.MultiSelect));
      await tester.selectOption(name: "asdf");
      await tester.dismissCellEditor();

      tester.assertNumberOfEventsInCalendar(1);

      await tester.tapFilterButtonInGrid('Tags');
      await tester.changeSelectFilterCondition(
        SelectOptionFilterConditionPB.OptionIsEmpty,
      );
      await tester.dismissCellEditor();

      tester.assertNumberOfEventsInCalendar(1);
      tester.assertNumberOfEventsOnSpecificDay(1, secondOfThisMonth);
    });
  });
}
