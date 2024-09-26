import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/view/database_field_list.dart';
import 'package:appflowy/mobile/presentation/database/view/database_filter_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/view/database_sort_bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MobileDatabaseControlFeatures { sort, filter }

class MobileDatabaseControls extends StatelessWidget {
  const MobileDatabaseControls({
    super.key,
    required this.controller,
    required this.features,
  });

  final DatabaseController controller;
  final List<MobileDatabaseControlFeatures> features;

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
        BlocProvider<SortEditorBloc>(
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

          return SeparatedRow(
            separatorBuilder: () => const HSpace(8.0),
            children: [
              if (features.contains(MobileDatabaseControlFeatures.sort))
                _DatabaseControlButton(
                  icon: FlowySvgs.sort_ascending_s,
                  count: context.watch<SortEditorBloc>().state.sorts.length,
                  onTap: () => _showEditSortPanelFromToolbar(
                    context,
                    controller,
                  ),
                ),
              if (features.contains(MobileDatabaseControlFeatures.filter))
                _DatabaseControlButton(
                  icon: FlowySvgs.filter_s,
                  count: context.watch<FilterEditorBloc>().state.filters.length,
                  onTap: () => _showEditFilterPanelFromToolbar(
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
    backgroundColor: AFThemeExtension.of(context).background,
    builder: (_) {
      return BlocProvider.value(
        value: context.read<SortEditorBloc>(),
        child: const MobileSortEditor(),
      );
    },
  );
}

void _showEditFilterPanelFromToolbar(
  BuildContext context,
  DatabaseController databaseController,
) {
  showMobileBottomSheet(
    context,
    showDragHandle: true,
    showDivider: false,
    useSafeArea: false,
    backgroundColor: AFThemeExtension.of(context).background,
    builder: (_) {
      return BlocProvider.value(
        value: context.read<FilterEditorBloc>(),
        child: const MobileFilterEditor(),
      );
    },
  );
}
