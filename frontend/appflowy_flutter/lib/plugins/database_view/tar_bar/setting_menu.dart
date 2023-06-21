import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_accessory_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../application/field/field_controller.dart';
import '../grid/presentation/layout/sizes.dart';
import '../grid/presentation/widgets/filter/filter_menu.dart';
import '../grid/presentation/widgets/sort/sort_menu.dart';

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
            return const SizedBox();
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
        final children = <Widget>[
          Divider(
            height: 1.0,
            color: AFThemeExtension.of(context).toggleOffFill,
          ),
          const VSpace(6),
          IntrinsicHeight(
            child: Row(
              children: [
                SortMenu(
                  fieldController: fieldController,
                ),
                const HSpace(6),
                FilterMenu(
                  fieldController: fieldController,
                ),
              ],
            ),
          )
        ];

        return _wrapPadding(
          Column(children: children),
        );
      },
    );
  }

  Widget _wrapPadding(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GridSize.leadingHeaderPadding,
        vertical: 6,
      ),
      child: child,
    );
  }
}
