import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberedRedDot extends StatelessWidget {
  const NumberedRedDot.desktop({
    super.key,
    this.fontSize = 10,
  }) : size = const NumberedSize(
          min: Size.square(14),
          middle: Size(17, 14),
          max: Size(24, 14),
        );

  const NumberedRedDot.mobile({
    super.key,
    this.fontSize = 14,
  }) : size = const NumberedSize(
          min: Size.square(20),
          middle: Size(26, 20),
          max: Size(35, 20),
        );

  const NumberedRedDot({
    super.key,
    required this.size,
    required this.fontSize,
  });
  final NumberedSize size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        int unreadReminder = 0;
        for (final reminder in state.reminders) {
          if (!reminder.isRead) unreadReminder++;
        }
        if (unreadReminder == 0) return SizedBox.shrink();
        final overNumber = unreadReminder > 99;
        Size size = this.size.min;
        if (unreadReminder >= 10 && unreadReminder <= 99) {
          size = this.size.middle;
        } else if (unreadReminder > 99) {
          size = this.size.max;
        }
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: theme.borderColorScheme.errorThick,
            borderRadius: BorderRadius.all(Radius.circular(size.height / 2)),
          ),
          child: Center(
            child: Text(
              overNumber ? '99+' : '$unreadReminder',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: fontSize,
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class NumberedSize {
  const NumberedSize({
    required this.min,
    required this.middle,
    required this.max,
  });

  final Size min;
  final Size middle;
  final Size max;
}
