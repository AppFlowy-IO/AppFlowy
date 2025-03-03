import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'filter_button.dart';
import 'sort_button.dart';
import 'view_database_button.dart';

class GridSettingBar extends StatelessWidget {
  const GridSettingBar({
    super.key,
    required this.controller,
    required this.toggleExtension,
  });

  final DatabaseController controller;
  final ToggleExtensionNotifier toggleExtension;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FilterEditorBloc(
            viewId: controller.viewId,
            fieldController: controller.fieldController,
          ),
        ),
        BlocProvider(
          create: (context) => SortEditorBloc(
            viewId: controller.viewId,
            fieldController: controller.fieldController,
          ),
        ),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const SizedBox.shrink();
          }
          final isReference =
              Provider.of<ReferenceState?>(context)?.isReference ?? false;
          return SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilterButton(toggleExtension: toggleExtension),
                const HSpace(6),
                SortButton(toggleExtension: toggleExtension),
                const HSpace(6),
                SettingButton(databaseController: controller),
                if (isReference) const HSpace(6),
                if (isReference) ViewDatabaseButton(view: controller.view),
              ],
            ),
          );
        },
      ),
    );
  }
}
