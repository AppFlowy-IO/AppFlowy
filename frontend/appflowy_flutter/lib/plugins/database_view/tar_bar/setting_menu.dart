import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_accessory_bloc.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/field/field_controller.dart';
import '../grid/presentation/layout/sizes.dart';
import '../grid/presentation/widgets/filter/filter_menu.dart';
import '../grid/presentation/widgets/sort/sort_menu.dart';

class DatabaseViewSettingBar extends StatelessWidget {
  final String viewId;
  final DatabaseController databaseController;
  const DatabaseViewSettingBar({
    required this.viewId,
    required this.databaseController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GridAccessoryMenuBloc(viewId: viewId),
      child: BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
        builder: (context, state) {
          if (state.isVisible) {
            return _DatabaseViewSettingContent(
              fieldController: databaseController.fieldController,
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
    // return BlocProvider(
    //   create: (context) => GridAccessoryMenuBloc(viewId: viewId),
    //   child: MultiBlocListener(
    //     listeners: [
    //       // BlocListener<GridFilterMenuBloc, GridFilterMenuState>(
    //       //   listenWhen: (p, c) => p.isVisible != c.isVisible,
    //       //   listener: (context, state) => context
    //       //       .read<GridAccessoryMenuBloc>()
    //       //       .add(const GridAccessoryMenuEvent.toggleMenu()),
    //       // ),
    //       // BlocListener<SortMenuBloc, SortMenuState>(
    //       //   listenWhen: (p, c) => p.isVisible != c.isVisible,
    //       //   listener: (context, state) => context
    //       //       .read<GridAccessoryMenuBloc>()
    //       //       .add(const GridAccessoryMenuEvent.toggleMenu()),
    //       // ),
    //     ],
    //     child: BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
    //       builder: (context, state) {
    //         if (state.isVisible) {
    //           return DatabaseViewSettingMenuContent(
    //             fieldController: databaseController.fieldController,
    //           );
    //         } else {
    //           return const SizedBox();
    //         }
    //       },
    //     ),
    //   ),
    // );
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
    return BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
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
