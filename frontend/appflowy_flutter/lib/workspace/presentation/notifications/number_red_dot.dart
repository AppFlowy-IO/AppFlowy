import 'dart:math';

import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberedRedDot extends StatelessWidget {
  const NumberedRedDot({
    super.key,
    this.size = 18,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        int unreadReminder = 0;
        for (final reminder in state.reminders) {
          if (!reminder.isRead) unreadReminder++;
        }
        if (unreadReminder == 0) return SizedBox.shrink();
        final overNumber = unreadReminder > 99;
        final fontSize = max(size - 6, size / 3);
        double? width = size;
        final horizontalPadding = size / 4;
        if (unreadReminder >= 10 && unreadReminder < 100) {
          width = size + horizontalPadding;
        } else if (unreadReminder >= 100) {
          width = size + horizontalPadding * 3;
        }
        return Container(
          height: size,
          width: width,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.all(Radius.circular(size / 2)),
          ),
          child: Center(
            child: Text(
              overNumber ? '99+' : '$unreadReminder',
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
