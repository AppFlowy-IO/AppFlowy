import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_button.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'filter_button.dart';
import 'sort_button.dart';

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
        BlocProvider<DatabaseFilterMenuBloc>(
          create: (context) => DatabaseFilterMenuBloc(
            viewId: controller.viewId,
            fieldController: controller.fieldController,
          )..add(const DatabaseFilterMenuEvent.initial()),
        ),
        BlocProvider<SortEditorBloc>(
          create: (context) => SortEditorBloc(
            viewId: controller.viewId,
            fieldController: controller.fieldController,
          ),
        ),
      ],
      child: BlocListener<DatabaseFilterMenuBloc, DatabaseFilterMenuState>(
        listenWhen: (p, c) => p.isVisible != c.isVisible,
        listener: (context, state) => toggleExtension.toggle(),
        child: ValueListenableBuilder<bool>(
          valueListenable: controller.isLoading,
          builder: (context, value, child) {
            if (value) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const FilterButton(),
                  const HSpace(2),
                  SortButton(toggleExtension: toggleExtension),
                  const HSpace(2),
                  SettingButton(
                    databaseController: controller,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
