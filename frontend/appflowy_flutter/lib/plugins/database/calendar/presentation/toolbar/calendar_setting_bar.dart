import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_button.dart';
import 'package:flutter/material.dart';

class CalendarSettingBar extends StatelessWidget {
  const CalendarSettingBar({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SettingButton(
            databaseController: databaseController,
          ),
        ],
      ),
    );
  }
}
