import 'package:appflowy/plugins/database/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  setUp(() async {
    await AppFlowyUnitTest.ensureInitialized();
  });

  testWidgets(
      'FirstDayOfWeek displays Sunday, Monday, and Saturday options (Issue #9134)',
      (tester) async {
    int? selectedDay;
    final mutex = PopoverMutex();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FirstDayOfWeek(
              firstDayOfWeek: 0,
              popoverMutex: mutex,
              onUpdated: (day) => selectedDay = day,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap FirstDayOfWeek button to open popover
    await tester.tap(find.byType(FirstDayOfWeek));
    await tester.pumpAndSettle();

    // Verify 3 StartFromButton widgets are rendered (Sunday, Monday, Saturday)
    expect(find.byType(StartFromButton), findsNWidgets(3));

    // Tap Saturday (dayIndex 6, third option)
    final saturdayFinder = find.byWidgetPredicate(
      (widget) => widget is StartFromButton && widget.dayIndex == 6,
    );
    expect(saturdayFinder, findsOneWidget);

    await tester.tap(saturdayFinder);
    await tester.pumpAndSettle();

    expect(selectedDay, 6);
  });
}
