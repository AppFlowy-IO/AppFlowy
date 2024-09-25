import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'database_sort_bottom_sheet_cubit.dart';

class MobileSortEditor extends StatefulWidget {
  const MobileSortEditor({
    super.key,
  });

  @override
  State<MobileSortEditor> createState() => _MobileSortEditorState();
}

class _MobileSortEditorState extends State<MobileSortEditor> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MobileSortEditorCubit(
        pageController: _pageController,
      ),
      child: Column(
        children: [
          const _Header(),
          SizedBox(
            height: 400, //314,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom,
                        ),
                        child: const _Overview(),
                      )
                    : const _SortDetail();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MobileSortEditorCubit, MobileSortEditorState>(
      builder: (context, state) {
        return SizedBox(
          height: 44.0,
          child: Stack(
            children: [
              if (state.showBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBarBackButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    onTap: () => context
                        .read<MobileSortEditorCubit>()
                        .returnToOverview(),
                  ),
                ),
              Align(
                child: FlowyText.medium(
                  LocaleKeys.grid_settings_sort.tr(),
                  fontSize: 16.0,
                ),
              ),
              if (state.isCreatingNewSort)
                Align(
                  alignment: Alignment.centerRight,
                  child: AppBarSaveButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    enable: state.newSortFieldId != null,
                    onTap: () {
                      _tryCreateSort(context, state);
                      context.read<MobileSortEditorCubit>().returnToOverview();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _tryCreateSort(BuildContext context, MobileSortEditorState state) {
    if (state.newSortFieldId != null && state.newSortCondition != null) {
      context.read<SortEditorBloc>().add(
            SortEditorEvent.createSort(
              fieldId: state.newSortFieldId!,
              condition: state.newSortCondition!,
            ),
          );
    }
  }
}

class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: state.sorts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlowySvg(
                            FlowySvgs.sort_descending_s,
                            size: const Size.square(60),
                            color: Theme.of(context).hintColor,
                          ),
                          FlowyText(
                            LocaleKeys.grid_sort_empty.tr(),
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      proxyDecorator: (child, index, animation) => Material(
                        color: Colors.transparent,
                        child: child,
                      ),
                      onReorder: (oldIndex, newIndex) => context
                          .read<SortEditorBloc>()
                          .add(SortEditorEvent.reorderSort(oldIndex, newIndex)),
                      itemCount: state.sorts.length,
                      itemBuilder: (context, index) => _SortItem(
                        key: ValueKey("sort_item_$index"),
                        sort: state.sorts[index],
                      ),
                    ),
            ),
            Container(
              height: 44,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(
                    width: 0.5,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                borderRadius: Corners.s10Border,
              ),
              child: InkWell(
                onTap: () {
                  final firstField = context
                      .read<SortEditorBloc>()
                      .state
                      .creatableFields
                      .firstOrNull;
                  if (firstField == null) {
                    Fluttertoast.showToast(
                      msg: LocaleKeys.grid_sort_cannotFindCreatableField.tr(),
                      gravity: ToastGravity.BOTTOM,
                    );
                  } else {
                    context.read<MobileSortEditorCubit>().startCreatingSort();
                  }
                },
                borderRadius: Corners.s10Border,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FlowySvg(
                        FlowySvgs.add_s,
                        size: Size.square(16),
                      ),
                      const HSpace(6.0),
                      FlowyText(
                        LocaleKeys.grid_sort_addSort.tr(),
                        fontSize: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SortItem extends StatelessWidget {
  const _SortItem({super.key, required this.sort});

  final SortInfo sort;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context
                .read<MobileSortEditorCubit>()
                .startEditingSort(sort.sortId),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: FlowyText.medium(
                      LocaleKeys.grid_sort_by.tr(),
                      fontSize: 15,
                    ),
                  ),
                  const VSpace(10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(
                                width: 0.5,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            borderRadius: Corners.s10Border,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: FlowyText(
                                    sort.fieldInfo.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const HSpace(6.0),
                                FlowySvg(
                                  FlowySvgs.icon_right_small_ccm_outlined_s,
                                  size: const Size.square(14),
                                  color: Theme.of(context).hintColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const HSpace(6),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(
                                width: 0.5,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            borderRadius: Corners.s10Border,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          padding: const EdgeInsetsDirectional.only(
                            start: 12,
                            end: 10,
                          ),
                          child: Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: FlowyText(
                                    sort.sortPB.condition.name,
                                  ),
                                ),
                                const HSpace(6.0),
                                FlowySvg(
                                  FlowySvgs.icon_right_small_ccm_outlined_s,
                                  size: const Size.square(14),
                                  color: Theme.of(context).hintColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 9,
            child: InkWell(
              onTap: () => context
                  .read<SortEditorBloc>()
                  .add(SortEditorEvent.deleteSort(sort)),
              // steal from the container LongClickReorderWidget thing
              onLongPress: () {},
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 34,
                child: Center(
                  child: FlowySvg(
                    FlowySvgs.trash_m,
                    size: const Size.square(18),
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortDetail extends StatelessWidget {
  const _SortDetail();

  @override
  Widget build(BuildContext context) {
    final isCreatingNewSort =
        context.read<MobileSortEditorCubit>().state.isCreatingNewSort;

    return isCreatingNewSort
        ? const _SortDetailContent()
        : BlocSelector<SortEditorBloc, SortEditorState, SortInfo>(
            selector: (state) => state.sorts.firstWhere(
              (sortInfo) =>
                  sortInfo.sortId ==
                  context.read<MobileSortEditorCubit>().state.editingSortId,
            ),
            builder: (context, sortInfo) {
              return _SortDetailContent(sortInfo: sortInfo);
            },
          );
  }
}

class _SortDetailContent extends StatelessWidget {
  const _SortDetailContent({
    this.sortInfo,
  });

  final SortInfo? sortInfo;

  bool get isCreatingNewSort => sortInfo == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DefaultTabController(
            length: 2,
            initialIndex: isCreatingNewSort
                ? 0
                : sortInfo!.sortPB.condition == SortConditionPB.Ascending
                    ? 0
                    : 1,
            child: Container(
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).hoverColor,
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                indicatorWeight: 0,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surface,
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                onTap: (index) {
                  final newCondition = index == 0
                      ? SortConditionPB.Ascending
                      : SortConditionPB.Descending;
                  _changeCondition(context, newCondition);
                },
                tabs: [
                  Tab(
                    height: 34,
                    child: Center(
                      child: FlowyText(
                        LocaleKeys.grid_sort_ascending.tr(),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Tab(
                    height: 34,
                    child: Center(
                      child: FlowyText(
                        LocaleKeys.grid_sort_descending.tr(),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const VSpace(20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FlowyText(
            LocaleKeys.grid_settings_sortBy.tr().toUpperCase(),
            fontSize: 13,
            color: Theme.of(context).hintColor,
          ),
        ),
        const VSpace(4.0),
        const Divider(
          height: 0.5,
          thickness: 0.5,
        ),
        Expanded(
          child: BlocBuilder<SortEditorBloc, SortEditorState>(
            builder: (context, state) {
              final fields = state.allFields
                  .where((field) => field.fieldType.canCreateSort)
                  .toList();
              return ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final fieldInfo = fields[index];
                  final isSelected = isCreatingNewSort
                      ? context
                              .watch<MobileSortEditorCubit>()
                              .state
                              .newSortFieldId ==
                          fieldInfo.id
                      : sortInfo!.fieldId == fieldInfo.id;

                  final canSort =
                      fieldInfo.fieldType.canCreateSort && !fieldInfo.hasSort;
                  final beingEdited =
                      !isCreatingNewSort && sortInfo!.fieldId == fieldInfo.id;
                  final enabled = canSort || beingEdited;

                  return FlowyOptionTile.checkbox(
                    text: fieldInfo.field.name,
                    isSelected: isSelected,
                    textColor: enabled ? null : Theme.of(context).disabledColor,
                    showTopBorder: false,
                    onTap: () {
                      if (isSelected) {
                        return;
                      }
                      if (enabled) {
                        _changeFieldId(context, fieldInfo.id);
                      } else {
                        Fluttertoast.showToast(
                          msg: LocaleKeys.grid_sort_fieldInUse.tr(),
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _changeCondition(BuildContext context, SortConditionPB newCondition) {
    if (isCreatingNewSort) {
      context.read<MobileSortEditorCubit>().changeSortCondition(newCondition);
    } else {
      context.read<SortEditorBloc>().add(
            SortEditorEvent.editSort(
              sortId: sortInfo!.sortId,
              condition: newCondition,
            ),
          );
    }
  }

  void _changeFieldId(BuildContext context, String newFieldId) {
    if (isCreatingNewSort) {
      context.read<MobileSortEditorCubit>().changeFieldId(newFieldId);
    } else {
      context.read<SortEditorBloc>().add(
            SortEditorEvent.editSort(
              sortId: sortInfo!.sortId,
              fieldId: newFieldId,
            ),
          );
    }
  }
}
