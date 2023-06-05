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
  const GridAccessoryMenu({required this.viewId, final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => GridAccessoryMenuBloc(viewId: viewId),
      child: MultiBlocListener(
        listeners: [
          BlocListener<GridFilterMenuBloc, GridFilterMenuState>(
            listenWhen: (final p, final c) => p.isVisible != c.isVisible,
            listener: (final context, final state) => context
                .read<GridAccessoryMenuBloc>()
                .add(const GridAccessoryMenuEvent.toggleMenu()),
          ),
          BlocListener<SortMenuBloc, SortMenuState>(
            listenWhen: (final p, final c) => p.isVisible != c.isVisible,
            listener: (final context, final state) => context
                .read<GridAccessoryMenuBloc>()
                .add(const GridAccessoryMenuEvent.toggleMenu()),
          ),
        ],
        child: BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
          builder: (final context, final state) {
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
  const _AccessoryMenu({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocBuilder<GridAccessoryMenuBloc, GridAccessoryMenuState>(
      builder: (final context, final state) {
        return _wrapPadding(
          Column(
            children: [
              Divider(
                height: 1.0,
                color: AFThemeExtension.of(context).toggleOffFill,
              ),
              const VSpace(6),
              IntrinsicHeight(
                child: Row(
                  children: const [
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

  Widget _wrapPadding(final Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GridSize.leadingHeaderPadding,
        vertical: 6,
      ),
      child: child,
    );
  }
}
