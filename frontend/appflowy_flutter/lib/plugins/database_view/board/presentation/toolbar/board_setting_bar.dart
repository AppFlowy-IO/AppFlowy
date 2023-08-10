import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
import 'package:flutter/material.dart';

class BoardSettingBar extends StatelessWidget {
  final DatabaseController databaseController;
  const BoardSettingBar({
    required this.databaseController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SettingButton(databaseController: databaseController),
        ],
      ),
    );
  }
}
