import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberedRedDot extends StatelessWidget {
  const NumberedRedDot({
    super.key,
    this.size = 18,
    this.fontSize = 12,
    this.figmaLineHeight = 14,
  });
  final double size;
  final double fontSize;
  final double figmaLineHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        int unreadReminder = 0;
        for (final reminder in state.reminders) {
          if (!reminder.isRead) unreadReminder++;
        }
        if (unreadReminder == 0) return SizedBox.shrink();
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Center(
            child: FlowyText.medium(
              '$unreadReminder',
              color: Colors.white,
              fontSize: fontSize,
              figmaLineHeight: figmaLineHeight,
            ),
          ),
        );
      },
    );
  }
}
