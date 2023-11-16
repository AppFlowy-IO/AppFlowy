import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_accessory_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_menu.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_menu.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class DatabaseViewSettingExtension extends StatelessWidget {
  final String viewId;
  final DatabaseController databaseController;
  final ToggleExtensionNotifier toggleExtension;
  const DatabaseViewSettingExtension({
    required this.viewId,
    required this.databaseController,
    required this.toggleExtension,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: toggleExtension,
      child: Consumer<ToggleExtensionNotifier>(
        builder: (context, value, child) {
          if (value.isToggled) {
            return BlocProvider(
              create: (context) =>
                  DatabaseViewSettingExtensionBloc(viewId: viewId),
              child: _DatabaseViewSettingContent(
                fieldController: databaseController.fieldController,
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class _DatabaseViewSettingContent extends StatelessWidget {
  final FieldController fieldController;
  const _DatabaseViewSettingContent({
    required this.fieldController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseViewSettingExtensionBloc,
        DatabaseViewSettingExtensionState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: GridSize.leadingHeaderPadding,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SortMenu(fieldController: fieldController),
                  const HSpace(6),
                  FilterMenu(fieldController: fieldController),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
