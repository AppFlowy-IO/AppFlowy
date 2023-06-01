import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardToolbar extends StatelessWidget {
  const BoardToolbar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const Spacer(),
          SettingButton(
            databaseController: context.read<BoardBloc>().databaseController,
          ),
        ],
      ),
    );
  }
}
