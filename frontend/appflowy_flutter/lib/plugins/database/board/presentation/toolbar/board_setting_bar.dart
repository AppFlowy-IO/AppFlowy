import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/filter_button.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardSettingBar extends StatelessWidget {
  const BoardSettingBar({
    super.key,
    required this.databaseController,
    required this.toggleExtension,
  });

  final DatabaseController databaseController;
  final ToggleExtensionNotifier toggleExtension;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FilterEditorBloc(
        viewId: databaseController.viewId,
        fieldController: databaseController.fieldController,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: databaseController.isLoading,
        builder: (context, value, child) {
          if (value) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilterButton(
                  toggleExtension: toggleExtension,
                ),
                const HSpace(2),
                SettingButton(
                  databaseController: databaseController,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
