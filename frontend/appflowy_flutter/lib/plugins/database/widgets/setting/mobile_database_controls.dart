import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/view/database_field_list.dart';
import 'package:appflowy/mobile/presentation/database/view/database_sort_bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const SizedBox.shrink();
            }

            return SeparatedRow(
              separatorBuilder: () => const HSpace(8.0),
              children: [
                _DatabaseControlButton(
                  icon: FlowySvgs.sort_ascending_s,
                  count: context.watch<SortEditorBloc>().state.sortInfos.length,
                  onTap: () => _showEditSortPanelFromToolbar(
                    context,
                    controller,
                  ),
                ),
                _DatabaseControlButton(
                  icon: FlowySvgs.m_field_hide_s,
                  onTap: () => _showDatabaseFieldListFromToolbar(
                    context,
                    controller,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DatabaseControlButton extends StatelessWidget {
  const _DatabaseControlButton({
    required this.onTap,
    required this.icon,
    this.count = 0,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: count == 0
            ? FlowySvg(
                icon,
                size: const Size.square(20),
              )
            : Row(
                children: [
                  FlowySvg(
                    icon,
                    size: const Size.square(20),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const HSpace(2.0),
                  FlowyText.medium(
                    count.toString(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
      ),
    );
  }
}

void _showDatabaseFieldListFromToolbar(
  BuildContext context,
  DatabaseController databaseController,
) {
  showTransitionMobileBottomSheet(
    context,
    showHeader: true,
    showBackButton: true,
    title: LocaleKeys.grid_settings_properties.tr(),
    showDivider: true,
    builder: (_) {
      return BlocProvider.value(
        value: context.read<ViewBloc>(),
        child: MobileDatabaseFieldList(
          databaseController: databaseController,
          canCreate: false,
        ),
      );
    },
  );
}

void _showEditSortPanelFromToolbar(
  BuildContext context,
  DatabaseController databaseController,
) {
  showMobileBottomSheet(
    context,
    showDragHandle: true,
    showDivider: false,
    useSafeArea: false,
    backgroundColor: Theme.of(context).colorScheme.background,
    builder: (_) {
      return BlocProvider.value(
        value: context.read<SortEditorBloc>(),
        child: const MobileSortEditor(),
      );
    },
  );
}
