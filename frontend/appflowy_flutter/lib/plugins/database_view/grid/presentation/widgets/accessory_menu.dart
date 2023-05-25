import 'package:appflowy/plugins/database_view/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_accessory_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/sort/sort_menu_bloc.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../layout/sizes.dart';
import 'filter/filter_menu.dart';
import 'sort/sort_menu.dart';

class GridAccessoryMenu extends StatelessWidget {
  final String viewId;
  const GridAccessoryMenu({required this.viewId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GridAccessoryMenuBloc(viewId: viewId),
      child: MultiBlocListener(
        listeners: [
          BlocListener<GridFilterMenuBloc, GridFilterMenuState>(
            listenWhen: (p, c) => p.isVisible != c.isVisible,
            listener: (context, state) => context
                .read<GridAccessoryMenuBloc>()
                .add(const GridAccessoryMenuEvent.toggleMenu()),
          ),
          BlocListener<SortMenuBloc, SortMenuState>(
            listenWhen: (p, c) => p.isVisible != c.isVisible,
            listener: (context, state) => context
                .read<GridAccessoryMenuBloc>()
                .add(const GridAccessoryMenuEvent.toggleMenu()),
          ),
        ],
        child: BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
          builder: (context, state) {
            if (state.isVisible) {
              return const _AccessoryMenu();
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}

class _AccessoryMenu extends StatelessWidget {
  const _AccessoryMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
      builder: (context, state) {
        return _wrapPadding(
          Column(
            children: [
              Divider(
                height: 1.0,
                color: AFThemeExtension.of(context).toggleOffFill,
              ),
              const VSpace(6),
              const IntrinsicHeight(
                child: Row(
                  children: [
                    SortMenu(),
                    HSpace(6),
                    FilterMenu(),
                  ],
                ),
              ),
            ],
          ),
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
