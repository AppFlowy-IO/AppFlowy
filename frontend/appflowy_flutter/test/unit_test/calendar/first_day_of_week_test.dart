import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/user_first_day_of_week.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  group('First day of the week mapping tests (Issue #9134)', () {
    test('calendarWeekDayFromInt correctly maps weekday integers', () {
      // 0 = Sunday
      expect(calendarWeekDayFromInt(0), WeekDays.sunday);
      // 1 = Monday
      expect(calendarWeekDayFromInt(1), WeekDays.monday);
      // 2 = Tuesday
      expect(calendarWeekDayFromInt(2), WeekDays.tuesday);
      // 3 = Wednesday
      expect(calendarWeekDayFromInt(3), WeekDays.wednesday);
      // 4 = Thursday
      expect(calendarWeekDayFromInt(4), WeekDays.thursday);
      // 5 = Friday
      expect(calendarWeekDayFromInt(5), WeekDays.friday);
      // 6 = Saturday (Issue #9134)
      expect(calendarWeekDayFromInt(6), WeekDays.saturday);
    });

    test('startingDayOfWeekFromInt correctly maps to StartingDayOfWeek enum',
        () {
      // null defaults to Sunday
      expect(startingDayOfWeekFromInt(null), StartingDayOfWeek.sunday);
      // 0 = Sunday
      expect(startingDayOfWeekFromInt(0), StartingDayOfWeek.sunday);
      // 1 = Monday
      expect(startingDayOfWeekFromInt(1), StartingDayOfWeek.monday);
      // 2 = Tuesday
      expect(startingDayOfWeekFromInt(2), StartingDayOfWeek.tuesday);
      // 3 = Wednesday
      expect(startingDayOfWeekFromInt(3), StartingDayOfWeek.wednesday);
      // 4 = Thursday
      expect(startingDayOfWeekFromInt(4), StartingDayOfWeek.thursday);
      // 5 = Friday
      expect(startingDayOfWeekFromInt(5), StartingDayOfWeek.friday);
      // 6 = Saturday (Issue #9134)
      expect(startingDayOfWeekFromInt(6), StartingDayOfWeek.saturday);
    });

    test('UserFirstDayOfWeek caching and fallback resolution', () {
      UserFirstDayOfWeek.resetForTesting();
      expect(UserFirstDayOfWeek.get(), isNull);

      UserFirstDayOfWeek.set(6);
      expect(UserFirstDayOfWeek.get(), 6);

      UserFirstDayOfWeek.set(1);
      expect(UserFirstDayOfWeek.get(), 1);

      UserFirstDayOfWeek.set(0);
      expect(UserFirstDayOfWeek.get(), 0);

      UserFirstDayOfWeek.resetForTesting();
      expect(UserFirstDayOfWeek.get(), isNull);
    });

    testWidgets(
        'resolveFirstDayOfWeek resolves explicit, user preference and fallback',
        (tester) async {
      UserFirstDayOfWeek.resetForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // 1. Explicit override takes precedence
              expect(
                resolveFirstDayOfWeek(context, explicitFirstDayOfWeek: 6),
                6,
              );
              expect(
                resolveFirstDayOfWeek(context, explicitFirstDayOfWeek: 1),
                1,
              );

              // 2. Unset fallback returns null
              expect(resolveFirstDayOfWeek(context), isNull);

              // 3. User preference fallback (e.g. set in calendar settings)
              UserFirstDayOfWeek.set(6);
              expect(resolveFirstDayOfWeek(context), 6);

              UserFirstDayOfWeek.set(1);
              expect(resolveFirstDayOfWeek(context), 1);

              return const SizedBox();
            },
          ),
        ),
      );

      UserFirstDayOfWeek.resetForTesting();
    });
  });
}
