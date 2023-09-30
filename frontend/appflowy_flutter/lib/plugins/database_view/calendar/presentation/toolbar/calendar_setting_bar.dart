import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
import 'package:flutter/material.dart';

class CalendarSettingBar extends StatelessWidget {
  final DatabaseController databaseController;
  const CalendarSettingBar({
    required this.databaseController,
    super.key,
  });

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
