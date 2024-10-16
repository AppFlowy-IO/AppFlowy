import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/date.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_time_text_field.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_time_button.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time/time.dart';

import '../../integration_test/shared/util.dart';
import 'test_asset_bundle.dart';

const _mockDatePickerDelay = Duration(milliseconds: 200);

class _DatePickerDataStub {
  _DatePickerDataStub({
    required this.dateTime,
    required this.endDateTime,
    required this.includeTime,
    required this.isRange,
  });

  _DatePickerDataStub.empty()
      : dateTime = null,
        endDateTime = null,
        includeTime = false,
        isRange = false;

  DateTime? dateTime;
  DateTime? endDateTime;
  bool includeTime;
  bool isRange;
}

class _MockDatePicker extends StatefulWidget {
  const _MockDatePicker({
    this.data,
    this.dateFormat,
    this.timeFormat,
  });

  final _DatePickerDataStub? data;
  final DateFormatPB? dateFormat;
  final TimeFormatPB? timeFormat;

  @override
  State<_MockDatePicker> createState() => _MockDatePickerState();
}

class _MockDatePickerState extends State<_MockDatePicker> {
  late final _DatePickerDataStub data;
  late DateFormatPB dateFormat;
  late TimeFormatPB timeFormat;

  @override
  void initState() {
    super.initState();
    data = widget.data ?? _DatePickerDataStub.empty();
    dateFormat = widget.dateFormat ?? DateFormatPB.Friendly;
    timeFormat = widget.timeFormat ?? TimeFormatPB.TwelveHour;
  }

  void updateDateFormat(DateFormatPB dateFormat) async {
    setState(() {
      this.dateFormat = dateFormat;
    });
  }

  void updateTimeFormat(TimeFormatPB timeFormat) async {
    setState(() {
      this.timeFormat = timeFormat;
    });
  }

  void updateDateCellData({
    required DateTime? dateTime,
    required DateTime? endDateTime,
    required bool isRange,
    required bool includeTime,
  }) {
    setState(() {
      data.dateTime = dateTime;
      data.endDateTime = endDateTime;
      data.includeTime = includeTime;
      data.isRange = isRange;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyDatePicker(
      dateTime: data.dateTime,
      endDateTime: data.endDateTime,
      includeTime: data.includeTime,
      isRange: data.isRange,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      onDaySelected: (date) async {
        await Future.delayed(_mockDatePickerDelay);
        setState(() {
          data.dateTime = date;
        });
      },
      onRangeSelected: (start, end) async {
        await Future.delayed(_mockDatePickerDelay);
        setState(() {
          data.dateTime = start;
          data.endDateTime = end;
        });
      },
      onIncludeTimeChanged: (value) async {
        await Future.delayed(_mockDatePickerDelay);
        setState(() {
          data.includeTime = value;
        });
      },
      onIsRangeChanged: (value) async {
        await Future.delayed(_mockDatePickerDelay);
        setState(() {
          data.isRange = value;
        });
      },
    );
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableLevels = [];
    await EasyLocalization.ensureInitialized();
  });

  Finder dayInDatePicker(int day) {
    final findCalendar = find.byType(TableCalendar);
    final findDay = find.text(day.toString());

    return find.descendant(
      of: findCalendar,
      matching: findDay,
    );
  }

  _MockDatePickerState getMockState(WidgetTester tester) =>
      tester.state<_MockDatePickerState>(find.byType(_MockDatePicker));

  AppFlowyDatePickerState getAfState(WidgetTester tester) =>
      tester.state<AppFlowyDatePickerState>(find.byType(AppFlowyDatePicker));

  group('AppFlowy date picker: ', () {
    testWidgets('default state', (tester) async {
      await tester.pumpWidget(
        const WidgetTestApp(
          child: _MockDatePicker(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyDatePicker), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is DateTimeTextField && w.dateTime == null,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is DatePicker && w.selectedDay == null),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is IncludeTimeButton && !w.includeTime),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is EndTimeButton && !w.isRange),
        findsOneWidget,
      );
    });

    testWidgets('passed in state', (tester) async {
      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            data: _DatePickerDataStub(
              dateTime: DateTime(2024, 10, 12, 13),
              endDateTime: DateTime(2024, 10, 14, 5),
              includeTime: true,
              isRange: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyDatePicker), findsOneWidget);
      expect(find.byType(DateTimeTextField), findsNWidgets(2));
      expect(find.byType(DatePicker), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is IncludeTimeButton && w.includeTime),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is EndTimeButton && w.isRange),
        findsOneWidget,
      );
      final afState = getAfState(tester);
      expect(afState.focusedDateTime, DateTime(2024, 10, 12, 13));
    });

    testWidgets('date and time formats', (tester) async {
      final date = DateTime(2024, 10, 12, 13);
      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            dateFormat: DateFormatPB.Friendly,
            timeFormat: TimeFormatPB.TwelveHour,
            data: _DatePickerDataStub(
              dateTime: date,
              endDateTime: null,
              includeTime: true,
              isRange: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dateText = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field_date')),
        matching:
            find.text(DateFormat(DateFormatPB.Friendly.pattern).format(date)),
      );
      expect(dateText, findsOneWidget);

      final timeText = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field_time')),
        matching:
            find.text(DateFormat(TimeFormatPB.TwelveHour.pattern).format(date)),
      );
      expect(timeText, findsOneWidget);

      _MockDatePickerState mockState = getMockState(tester);
      mockState.updateDateFormat(DateFormatPB.US);
      await tester.pumpAndSettle();
      final dateText2 = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field_date')),
        matching: find.text(DateFormat(DateFormatPB.US.pattern).format(date)),
      );
      expect(dateText2, findsOneWidget);

      mockState = getMockState(tester);
      mockState.updateTimeFormat(TimeFormatPB.TwentyFourHour);
      await tester.pumpAndSettle();
      final timeText2 = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field_time')),
        matching: find
            .text(DateFormat(TimeFormatPB.TwentyFourHour.pattern).format(date)),
      );
      expect(timeText2, findsOneWidget);
    });

    testWidgets('page turn buttons', (tester) async {
      await tester.pumpWidget(
        const WidgetTestApp(
          child: _MockDatePicker(),
        ),
      );
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(
        find.text(DateFormat.yMMMM().format(now)),
        findsOneWidget,
      );

      final lastMonth = now.subtract(const Duration(days: 32));
      await tester.tap(find.byFlowySvg(FlowySvgs.arrow_left_s));
      await tester.pumpAndSettle();
      expect(
        find.text(DateFormat.yMMMM().format(lastMonth)),
        findsOneWidget,
      );

      await tester.tap(find.byFlowySvg(FlowySvgs.arrow_right_s));
      await tester.pumpAndSettle();
      expect(
        find.text(DateFormat.yMMMM().format(now)),
        findsOneWidget,
      );
    });

    testWidgets('select date', (tester) async {
      await tester.pumpWidget(
        const WidgetTestApp(
          child: _MockDatePicker(),
        ),
      );
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final third = dayInDatePicker(3).first;
      await tester.tap(third);
      await tester.pump();

      DateTime expected = DateTime(now.year, now.month, 3);

      AppFlowyDatePickerState afState = getAfState(tester);
      _MockDatePickerState mockState = getMockState(tester);
      expect(afState.dateTime, expected);
      expect(mockState.data.dateTime, null);

      await tester.pumpAndSettle();
      mockState = getMockState(tester);
      expect(mockState.data.dateTime, expected);

      final firstOfNextMonth = dayInDatePicker(1).last;
      await tester.tap(firstOfNextMonth);
      await tester.pumpAndSettle();

      expected = DateTime(now.year, now.month + 1);
      afState = getAfState(tester);
      expect(afState.dateTime, expected);
      expect(afState.focusedDateTime, expected);
    });

    testWidgets('select date range', (tester) async {
      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            data: _DatePickerDataStub(
              dateTime: null,
              endDateTime: null,
              includeTime: false,
              isRange: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppFlowyDatePickerState afState = getAfState(tester);
      _MockDatePickerState mockState = getMockState(tester);
      expect(afState.startDateTime, null);
      expect(afState.endDateTime, null);
      expect(mockState.data.dateTime, null);
      expect(mockState.data.endDateTime, null);

      // 3-10
      final now = DateTime.now();
      final third = dayInDatePicker(3).first;
      await tester.tap(third);
      await tester.pumpAndSettle();

      final expectedStart = DateTime(now.year, now.month, 3);
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.startDateTime, expectedStart);
      expect(afState.endDateTime, null);
      expect(mockState.data.dateTime, null);
      expect(mockState.data.endDateTime, null);

      final tenth = dayInDatePicker(10).first;
      await tester.tap(tenth);
      await tester.pump();

      final expectedEnd = DateTime(now.year, now.month, 10);
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.startDateTime, expectedStart);
      expect(afState.endDateTime, expectedEnd);
      expect(mockState.data.dateTime, null);
      expect(mockState.data.endDateTime, null);

      await tester.pumpAndSettle();
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.startDateTime, expectedStart);
      expect(afState.endDateTime, expectedEnd);
      expect(mockState.data.dateTime, expectedStart);
      expect(mockState.data.endDateTime, expectedEnd);

      // 7-18, backwards
      final eighteenth = dayInDatePicker(18).first;
      await tester.tap(eighteenth);
      await tester.pumpAndSettle();

      final expectedEnd2 = DateTime(now.year, now.month, 18);
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.startDateTime, expectedEnd2);
      expect(afState.endDateTime, null);
      expect(mockState.data.dateTime, expectedStart);
      expect(mockState.data.endDateTime, expectedEnd);

      final seventh = dayInDatePicker(7).first;
      await tester.tap(seventh);
      await tester.pump();

      final expectedStart2 = DateTime(now.year, now.month, 7);
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.startDateTime, expectedStart2);
      expect(afState.endDateTime, expectedEnd2);
      expect(mockState.data.dateTime, expectedStart);
      expect(mockState.data.endDateTime, expectedEnd);

      await tester.pumpAndSettle();
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.startDateTime, expectedStart2);
      expect(afState.endDateTime, expectedEnd2);
      expect(mockState.data.dateTime, expectedStart2);
      expect(mockState.data.endDateTime, expectedEnd2);
    });

    testWidgets('select date range after toggling is range', (tester) async {
      final now = DateTime.now();
      final fourteenthDateTime = DateTime(now.year, now.month, 14);

      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            data: _DatePickerDataStub(
              dateTime: fourteenthDateTime,
              endDateTime: null,
              includeTime: false,
              isRange: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppFlowyDatePickerState afState = getAfState(tester);
      _MockDatePickerState mockState = getMockState(tester);
      expect(afState.dateTime, fourteenthDateTime);
      expect(afState.startDateTime, null);
      expect(afState.endDateTime, null);
      expect(afState.justChangedIsRange, false);

      await tester.tap(
        find.descendant(
          of: find.byType(EndTimeButton),
          matching: find.byType(Toggle),
        ),
      );
      await tester.pump();

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, fourteenthDateTime);
      expect(afState.startDateTime, null);
      expect(afState.endDateTime, null);
      expect(afState.justChangedIsRange, true);
      expect(afState.isRange, true);
      expect(mockState.data.dateTime, fourteenthDateTime);
      expect(mockState.data.endDateTime, null);
      expect(mockState.data.isRange, false);

      await tester.pumpAndSettle();

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, fourteenthDateTime);
      expect(afState.startDateTime, fourteenthDateTime);
      expect(afState.endDateTime, fourteenthDateTime);
      expect(afState.justChangedIsRange, true);
      expect(mockState.data.dateTime, fourteenthDateTime);
      expect(mockState.data.endDateTime, fourteenthDateTime);
      expect(mockState.data.isRange, true);

      final twentyFirst = dayInDatePicker(21).first;
      await tester.tap(twentyFirst);
      await tester.pumpAndSettle();

      final expected = DateTime(now.year, now.month, 21);

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, fourteenthDateTime);
      expect(afState.startDateTime, fourteenthDateTime);
      expect(afState.endDateTime, expected);
      expect(afState.justChangedIsRange, false);
      expect(mockState.data.dateTime, fourteenthDateTime);
      expect(mockState.data.endDateTime, expected);
      expect(mockState.data.isRange, true);
    });

    testWidgets('include time and modify', (tester) async {
      final now = DateTime.now();
      final fourteenthDateTime = DateTime(now.year, now.month, 14);

      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            data: _DatePickerDataStub(
              dateTime: fourteenthDateTime,
              endDateTime: null,
              includeTime: false,
              isRange: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppFlowyDatePickerState afState = getAfState(tester);
      _MockDatePickerState mockState = getMockState(tester);
      expect(afState.dateTime, fourteenthDateTime);
      expect(afState.startDateTime, null);
      expect(afState.endDateTime, null);
      expect(afState.includeTime, false);

      await tester.tap(
        find.descendant(
          of: find.byType(IncludeTimeButton),
          matching: find.byType(Toggle),
        ),
      );
      await tester.pump();

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, fourteenthDateTime);
      expect(afState.includeTime, true);
      expect(mockState.data.dateTime, fourteenthDateTime);
      expect(mockState.data.includeTime, false);

      await tester.pumpAndSettle(300.milliseconds);
      mockState = getMockState(tester);
      expect(mockState.data.dateTime, fourteenthDateTime);
      expect(mockState.data.includeTime, true);

      final timeField = find.byKey(const ValueKey('date_time_text_field_time'));
      await tester.enterText(timeField, "1");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(300.milliseconds);

      DateTime expected = DateTime(
        fourteenthDateTime.year,
        fourteenthDateTime.month,
        fourteenthDateTime.day,
        1,
      );

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, expected);
      expect(mockState.data.dateTime, expected);

      final dateText = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field_date')),
        matching: find
            .text(DateFormat(DateFormatPB.Friendly.pattern).format(expected)),
      );
      expect(dateText, findsOneWidget);
      final timeText = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field_time')),
        matching: find
            .text(DateFormat(TimeFormatPB.TwelveHour.pattern).format(expected)),
      );
      expect(timeText, findsOneWidget);

      final third = dayInDatePicker(3).first;
      await tester.tap(third);
      await tester.pumpAndSettle();

      expected = DateTime(
        fourteenthDateTime.year,
        fourteenthDateTime.month,
        3,
        1,
      );

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, expected);
      expect(mockState.data.dateTime, expected);
    });

    testWidgets('edit text field causes start and end to get swapped',
        (tester) async {
      final fourteenth = DateTime(2024, 10, 14);

      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            data: _DatePickerDataStub(
              dateTime: fourteenth,
              endDateTime: fourteenth,
              includeTime: false,
              isRange: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          DateFormat(DateFormatPB.Friendly.pattern).format(fourteenth),
        ),
        findsNWidgets(2),
      );

      final dateTextField = find.descendant(
        of: find.byKey(const ValueKey('date_time_text_field')),
        matching: find.byKey(const ValueKey('date_time_text_field_date')),
      );
      expect(dateTextField, findsOneWidget);
      await tester.enterText(dateTextField, "Nov 30, 2024");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      final bday = DateTime(2024, 11, 30);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('date_time_text_field')),
          matching: find.text(
            DateFormat(DateFormatPB.Friendly.pattern).format(fourteenth),
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('end_date_time_text_field')),
          matching: find.text(
            DateFormat(DateFormatPB.Friendly.pattern).format(bday),
          ),
        ),
        findsOneWidget,
      );

      final mockState = getMockState(tester);
      expect(mockState.data.dateTime, fourteenth);
      expect(mockState.data.endDateTime, bday);
    });

    testWidgets('select start with calendar and then enter end with keyboard',
        (tester) async {
      final fourteenth = DateTime(2024, 10, 14);

      await tester.pumpWidget(
        WidgetTestApp(
          child: _MockDatePicker(
            data: _DatePickerDataStub(
              dateTime: fourteenth,
              endDateTime: fourteenth,
              includeTime: false,
              isRange: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final third = dayInDatePicker(3).first;
      await tester.tap(third);
      await tester.pumpAndSettle();

      final start = DateTime(2024, 10, 3);

      AppFlowyDatePickerState afState = getAfState(tester);
      _MockDatePickerState mockState = getMockState(tester);
      expect(afState.dateTime, start);
      expect(afState.startDateTime, start);
      expect(afState.endDateTime, null);
      expect(mockState.data.dateTime, fourteenth);
      expect(mockState.data.endDateTime, fourteenth);
      expect(mockState.data.isRange, true);

      final dateTextField = find.descendant(
        of: find.byKey(const ValueKey('end_date_time_text_field')),
        matching: find.byKey(const ValueKey('date_time_text_field_date')),
      );
      expect(dateTextField, findsOneWidget);
      await tester.enterText(dateTextField, "Oct 18, 2024");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      final end = DateTime(2024, 10, 18);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('date_time_text_field')),
          matching: find.text(
            DateFormat(DateFormatPB.Friendly.pattern).format(start),
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('end_date_time_text_field')),
          matching: find.text(
            DateFormat(DateFormatPB.Friendly.pattern).format(end),
          ),
        ),
        findsOneWidget,
      );

      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, start);
      expect(afState.startDateTime, start);
      expect(afState.endDateTime, end);
      expect(mockState.data.dateTime, start);
      expect(mockState.data.endDateTime, end);

      // make sure click counter was reset
      final twentyFifth = dayInDatePicker(25).first;
      final expected = DateTime(2024, 10, 25);
      await tester.tap(twentyFifth);
      await tester.pumpAndSettle();
      afState = getAfState(tester);
      mockState = getMockState(tester);
      expect(afState.dateTime, expected);
      expect(afState.startDateTime, expected);
      expect(afState.endDateTime, null);
      expect(mockState.data.dateTime, start);
      expect(mockState.data.endDateTime, end);
    });
  });
}

class WidgetTestApp extends StatelessWidget {
  const WidgetTestApp({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useFallbackTranslations: true,
      saveLocale: false,
      assetLoader: const TestBundleAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData.light().copyWith(
            extensions: const [
              AFThemeExtension(
                warning: Colors.transparent,
                success: Colors.transparent,
                tint1: Colors.transparent,
                tint2: Colors.transparent,
                tint3: Colors.transparent,
                tint4: Colors.transparent,
                tint5: Colors.transparent,
                tint6: Colors.transparent,
                tint7: Colors.transparent,
                tint8: Colors.transparent,
                tint9: Colors.transparent,
                textColor: Colors.transparent,
                secondaryTextColor: Colors.transparent,
                strongText: Colors.transparent,
                greyHover: Colors.transparent,
                greySelect: Colors.transparent,
                lightGreyHover: Colors.transparent,
                toggleOffFill: Colors.transparent,
                progressBarBGColor: Colors.transparent,
                toggleButtonBGColor: Colors.transparent,
                calendarWeekendBGColor: Colors.transparent,
                gridRowCountColor: Colors.transparent,
                code: TextStyle(),
                callout: TextStyle(),
                calloutBGColor: Colors.transparent,
                tableCellBGColor: Colors.transparent,
                caption: TextStyle(),
                onBackground: Colors.transparent,
                background: Colors.transparent,
                borderColor: Colors.transparent,
                scrollbarColor: Colors.transparent,
                scrollbarHoverColor: Colors.transparent,
              ),
            ],
          ),
          home: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }
}
