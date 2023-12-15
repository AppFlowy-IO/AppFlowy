import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/view/edit_database_view_screen.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_paginated_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/sort/sort_menu_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/database_settings_list.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileDatabaseControls extends StatelessWidget {
  const MobileDatabaseControls({
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

            return Row(
              children: [
                _DatabaseControlButton(
                  icon: FlowySvgs.settings_s,
                  onTap: () {
                    showMobileBottomSheet(
                      context,
                      padding: EdgeInsets.zero,
                      builder: (_) => MobileEditDatabaseViewScreen(
                        databaseController: controller,
                        viewPB: context.read<ViewBloc>().state.view,
                      ),
                    );
                  },
                ),
                _DatabaseControlButton(
                  icon: FlowySvgs.align_left_s,
                  onTap: () => _showMobileSettings(context, controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMobileSettings(
    BuildContext context,
    DatabaseController controller,
  ) =>
      showPaginatedBottomSheet(
        context,
        page: SheetPage(
          title: LocaleKeys.settings_title.tr(),
          body: DatabaseSettingsList(
            databaseController: controller,
          ),
        ),
      );
}

class _DatabaseControlButton extends StatelessWidget {
  const _DatabaseControlButton({
    required this.onTap,
    required this.icon,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 36,
      child: IconButton(
        splashRadius: 18,
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: FlowySvg(
          icon,
          size: const Size.square(20),
        ),
      ),
    );
  }
}
