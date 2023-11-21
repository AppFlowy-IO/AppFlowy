import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/sort/sort_menu_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileGridSettingButton extends StatelessWidget {
  final DatabaseController controller;
  final ToggleExtensionNotifier toggleExtension;
  const MobileGridSettingButton({
    required this.controller,
    required this.toggleExtension,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GridFilterMenuBloc>(
          create: (context) => GridFilterMenuBloc(
            viewId: controller.viewId,
            fieldController: controller.fieldController,
          )..add(const GridFilterMenuEvent.initial()),
        ),
        BlocProvider<SortMenuBloc>(
          create: (context) => SortMenuBloc(
            viewId: controller.viewId,
            fieldController: controller.fieldController,
          )..add(const SortMenuEvent.initial()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<GridFilterMenuBloc, GridFilterMenuState>(
            listenWhen: (p, c) => p.isVisible != c.isVisible,
            listener: (context, state) => toggleExtension.toggle(),
          ),
          BlocListener<SortMenuBloc, SortMenuState>(
            listenWhen: (p, c) => p.isVisible != c.isVisible,
            listener: (context, state) => toggleExtension.toggle(),
          ),
        ],
        child: ValueListenableBuilder<bool>(
          valueListenable: controller.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const SizedBox.shrink();
            }
            return IconButton(
              onPressed: () {},
              icon: const FlowySvg(
                FlowySvgs.m_setting_m,
              ),
            );
          },
        ),
      ),
    );
  }
}
