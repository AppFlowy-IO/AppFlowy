import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/database/view/database_filter_condition_list.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/date.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/mobile_select_option_editor.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/mobile_date_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:time/time.dart';

import 'database_filter_bottom_sheet_cubit.dart';

class MobileFilterEditor extends StatefulWidget {
  const MobileFilterEditor({super.key});

  @override
  State<MobileFilterEditor> createState() => _MobileFilterEditorState();
}

class _MobileFilterEditorState extends State<MobileFilterEditor> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MobileFilterEditorCubit(
        pageController: _pageController,
      ),
      child: Column(
        children: [
          const _Header(),
          SizedBox(
            height: 400,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return switch (index) {
                  0 => const _ActiveFilters(),
                  1 => const _FilterDetail(),
                  _ => const SizedBox.shrink(),
                };
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
    return BlocBuilder<MobileFilterEditorCubit, MobileFilterEditorState>(
      builder: (context, state) {
        return SizedBox(
          height: 44.0,
          child: Stack(
            children: [
              if (_isBackButtonShown(state))
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBarBackButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    onTap: () => context
                        .read<MobileFilterEditorCubit>()
                        .returnToOverview(),
                  ),
                ),
              Align(
                child: FlowyText.medium(
                  LocaleKeys.grid_settings_filter.tr(),
                  fontSize: 16.0,
                ),
              ),
              if (_isSaveButtonShown(state))
                Align(
                  alignment: Alignment.centerRight,
                  child: AppBarSaveButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    enable: _isSaveButtonEnabled(state),
                    onTap: () => _saveOnTapHandler(context, state),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isBackButtonShown(MobileFilterEditorState state) {
    return state.maybeWhen(
      overview: () => false,
      orElse: () => true,
    );
  }

  bool _isSaveButtonShown(MobileFilterEditorState state) {
    return state.maybeWhen(
      create: (_) => true,
      editField: (_, __) => true,
      editCondition: (filterId, newFilter, showSave) => showSave,
      editContent: (_, __) => true,
      orElse: () => false,
    );
  }

  bool _isSaveButtonEnabled(MobileFilterEditorState state) {
    return state.maybeWhen(
      create: (field) => field != null,
      editField: (_, __) => true,
      editCondition: (_, __, enableSave) => enableSave,
      editContent: (_, __) => true,
      orElse: () => false,
    );
  }

  void _saveOnTapHandler(BuildContext context, MobileFilterEditorState state) {
    state.maybeWhen(
      create: (filterField) {
        if (filterField != null) {
          context
              .read<FilterEditorBloc>()
              .add(FilterEditorEvent.createFilter(filterField));
        }
      },
      editField: (filterId, newField) {
        final filter = context
            .read<FilterEditorBloc>()
            .state
            .filters
            .firstWhereOrNull((filter) => filter.filterId == filterId);
        if (newField != null &&
            filter != null &&
            newField.id != filter.fieldId) {
          context
              .read<FilterEditorBloc>()
              .add(FilterEditorEvent.changeFilteringField(filterId, newField));
        }
      },
      editCondition: (filterId, newFilter, _) {
        context
            .read<FilterEditorBloc>()
            .add(FilterEditorEvent.updateFilter(newFilter));
      },
      editContent: (filterId, newFilter) {
        context
            .read<FilterEditorBloc>()
            .add(FilterEditorEvent.updateFilter(newFilter));
      },
      orElse: () {},
    );
    context.read<MobileFilterEditorCubit>().returnToOverview();
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterEditorBloc, FilterEditorState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              Expanded(
                child: state.filters.isEmpty
                    ? _emptyBackground(context)
                    : _filterList(context, state),
              ),
              const VSpace(12),
              const _CreateFilterButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyBackground(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.filter_s,
            size: const Size.square(60),
            color: Theme.of(context).hintColor,
          ),
          FlowyText(
            LocaleKeys.grid_filter_empty.tr(),
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }

  Widget _filterList(BuildContext context, FilterEditorState state) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      itemCount: state.filters.length,
      itemBuilder: (context, index) {
        final filter = state.filters[index];
        final field = context
            .read<FilterEditorBloc>()
            .state
            .fields
            .firstWhereOrNull((field) => field.id == filter.fieldId);
        return field == null
            ? const SizedBox.shrink()
            : _FilterItem(filter: filter, field: field);
      },
      separatorBuilder: (context, index) => const VSpace(12.0),
    );
  }
}

class _CreateFilterButton extends StatelessWidget {
  const _CreateFilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (context.read<FilterEditorBloc>().state.fields.isEmpty) {
            Fluttertoast.showToast(
              msg: LocaleKeys.grid_filter_cannotFindCreatableField.tr(),
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            context.read<MobileFilterEditorCubit>().startCreatingFilter();
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
                LocaleKeys.grid_filter_addFilter.tr(),
                fontSize: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.filter,
    required this.field,
  });

  final DatabaseFilter filter;
  final FieldInfo field;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
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
                    LocaleKeys.grid_filter_where.tr(),
                    fontSize: 15,
                  ),
                ),
                const VSpace(10),
                Row(
                  children: [
                    Expanded(
                      child: FilterItemInnerButton(
                        onTap: () => context
                            .read<MobileFilterEditorCubit>()
                            .startEditingFilterField(filter.filterId),
                        icon: field.fieldType.svgData,
                        child: FlowyText(
                          field.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const HSpace(6),
                    Expanded(
                      child: FilterItemInnerButton(
                        onTap: () => context
                            .read<MobileFilterEditorCubit>()
                            .startEditingFilterCondition(
                              filter.filterId,
                              filter,
                              filter.fieldType.isDate,
                            ),
                        child: FlowyText(
                          filter.conditionName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                if (filter.canAttachContent) ...[
                  const VSpace(6),
                  filter.getMobileDescription(
                    field,
                    onExpand: () => context
                        .read<MobileFilterEditorCubit>()
                        .startEditingFilterContent(filter.filterId, filter),
                    onUpdate: (newFilter) => context
                        .read<FilterEditorBloc>()
                        .add(FilterEditorEvent.updateFilter(newFilter)),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 6,
            child: _deleteButton(context),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return InkWell(
      onTap: () => context
          .read<FilterEditorBloc>()
          .add(FilterEditorEvent.deleteFilter(filter.filterId)),
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
    );
  }
}

class FilterItemInnerButton extends StatelessWidget {
  const FilterItemInnerButton({
    super.key,
    required this.onTap,
    required this.child,
    this.icon,
  });

  final VoidCallback onTap;
  final FlowySvgData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
          child: SeparatedRow(
            separatorBuilder: () => const HSpace(6.0),
            children: [
              if (icon != null)
                FlowySvg(
                  icon!,
                  size: const Size.square(16),
                ),
              Expanded(child: child),
              FlowySvg(
                FlowySvgs.icon_right_small_ccm_outlined_s,
                size: const Size.square(14),
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterItemInnerTextField extends StatefulWidget {
  const FilterItemInnerTextField({
    super.key,
    required this.content,
    required this.enabled,
    required this.onSubmitted,
  });

  final String content;
  final bool enabled;
  final void Function(String) onSubmitted;

  @override
  State<FilterItemInnerTextField> createState() =>
      _FilterItemInnerTextFieldState();
}

class _FilterItemInnerTextFieldState extends State<FilterItemInnerTextField> {
  late final TextEditingController textController =
      TextEditingController(text: widget.content);
  final FocusNode focusNode = FocusNode();
  final Debounce debounce = Debounce(duration: 300.milliseconds);

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        enabled: widget.enabled,
        focusNode: focusNode,
        controller: textController,
        onSubmitted: widget.onSubmitted,
        onChanged: (value) => debounce.call(() => widget.onSubmitted(value)),
        onTapOutside: (_) => focusNode.unfocus(),
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.enabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).disabledColor,
          enabledBorder: _getBorder(Theme.of(context).dividerColor),
          border: _getBorder(Theme.of(context).dividerColor),
          focusedBorder: _getBorder(Theme.of(context).colorScheme.primary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  InputBorder _getBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        width: 0.5,
        color: color,
      ),
      borderRadius: Corners.s10Border,
    );
  }
}

class _FilterDetail extends StatelessWidget {
  const _FilterDetail();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MobileFilterEditorCubit, MobileFilterEditorState>(
      builder: (context, state) {
        return state.maybeWhen(
          create: (filterField) {
            return _FilterableFieldList(
              onSelectField: (field) =>
                  context.read<MobileFilterEditorCubit>().changeField(field),
            );
          },
          editField: (filterId, newField) {
            return _FilterableFieldList(
              onSelectField: (field) {
                context.read<MobileFilterEditorCubit>().changeField(field);
              },
            );
          },
          editCondition: (filterId, newFilter, showSave) {
            return _FilterConditionList(
              filterId: filterId,
              onSelect: (newFilter) {
                context
                    .read<FilterEditorBloc>()
                    .add(FilterEditorEvent.updateFilter(newFilter));
                context.read<MobileFilterEditorCubit>().returnToOverview();
              },
            );
          },
          editContent: (filterId, filter) {
            return _FilterContentEditor(
              filter: filter,
              onUpdateFilter: (newFilter) {
                context.read<MobileFilterEditorCubit>().updateFilter(newFilter);
              },
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _FilterableFieldList extends StatelessWidget {
  const _FilterableFieldList({
    required this.onSelectField,
  });

  final void Function(FieldInfo field) onSelectField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(4.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FlowyText(
            LocaleKeys.grid_settings_filterBy.tr().toUpperCase(),
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
          child: BlocBuilder<FilterEditorBloc, FilterEditorState>(
            builder: (context, blocState) {
              return ListView.builder(
                itemCount: blocState.fields.length,
                itemBuilder: (context, index) {
                  return FlowyOptionTile.checkbox(
                    text: blocState.fields[index].name,
                    showTopBorder: false,
                    leftIcon: FlowySvg(
                      blocState.fields[index].fieldType.svgData,
                    ),
                    isSelected: _isSelected(context, blocState, index),
                    onTap: () => onSelectField(blocState.fields[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSelected(BuildContext context, FilterEditorState state, int index) {
    final field = state.fields[index];
    return context.watch<MobileFilterEditorCubit>().state.maybeWhen(
          create: (selectedField) {
            return selectedField != null && selectedField.id == field.id;
          },
          editField: (filterId, selectedField) {
            final filter = state.filters.firstWhereOrNull(
              (filter) => filter.filterId == filterId,
            );

            final isOriginalSelectedField =
                selectedField == null && filter?.fieldId == field.id;

            final isNewSelectedField =
                selectedField != null && selectedField.id == field.id;

            return isOriginalSelectedField || isNewSelectedField;
          },
          orElse: () => false,
        );
  }
}

class _FilterConditionList extends StatelessWidget {
  const _FilterConditionList({
    required this.filterId,
    required this.onSelect,
  });

  final String filterId;
  final void Function(DatabaseFilter filter) onSelect;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FilterEditorBloc, FilterEditorState, DatabaseFilter?>(
      selector: (state) => state.filters.firstWhereOrNull(
        (filter) => filter.filterId == filterId,
      ),
      builder: (context, filter) {
        if (filter == null) {
          return const SizedBox.shrink();
        }

        if (filter is DateTimeFilter?) {
          return _DateTimeFilterConditionList(
            onSelect: (filter) {
              context.read<MobileFilterEditorCubit>().updateFilter(filter);
            },
          );
        }

        final conditions =
            FilterCondition.fromFieldType(filter.fieldType).conditions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VSpace(4.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FlowyText(
                LocaleKeys.grid_filter_conditon.tr().toUpperCase(),
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
              child: ListView.builder(
                itemCount: conditions.length,
                itemBuilder: (context, index) {
                  return FlowyOptionTile.checkbox(
                    text: conditions[index].$2,
                    showTopBorder: false,
                    isSelected: _isSelected(filter, conditions[index].$1),
                    onTap: () {
                      final newFilter =
                          _updateCondition(filter, conditions[index].$1);
                      onSelect(newFilter);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSelected(DatabaseFilter filter, ProtobufEnum condition) {
    return switch (filter.fieldType) {
      FieldType.RichText ||
      FieldType.URL =>
        (filter as TextFilter).condition == condition,
      FieldType.Number => (filter as NumberFilter).condition == condition,
      FieldType.SingleSelect ||
      FieldType.MultiSelect =>
        (filter as SelectOptionFilter).condition == condition,
      FieldType.Checkbox => (filter as CheckboxFilter).condition == condition,
      FieldType.Checklist => (filter as ChecklistFilter).condition == condition,
      _ => false,
    };
  }

  DatabaseFilter _updateCondition(
    DatabaseFilter filter,
    ProtobufEnum condition,
  ) {
    return switch (filter.fieldType) {
      FieldType.RichText || FieldType.URL => (filter as TextFilter)
          .copyWith(condition: condition as TextFilterConditionPB),
      FieldType.Number => (filter as NumberFilter)
          .copyWith(condition: condition as NumberFilterConditionPB),
      FieldType.SingleSelect ||
      FieldType.MultiSelect =>
        (filter as SelectOptionFilter)
            .copyWith(condition: condition as SelectOptionFilterConditionPB),
      FieldType.Checkbox => (filter as CheckboxFilter)
          .copyWith(condition: condition as CheckboxFilterConditionPB),
      FieldType.Checklist => (filter as ChecklistFilter)
          .copyWith(condition: condition as ChecklistFilterConditionPB),
      _ => filter,
    };
  }
}

class _DateTimeFilterConditionList extends StatelessWidget {
  const _DateTimeFilterConditionList({
    required this.onSelect,
  });

  final void Function(DatabaseFilter) onSelect;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MobileFilterEditorCubit, MobileFilterEditorState>(
      builder: (context, state) {
        return state.maybeWhen(
          orElse: () => const SizedBox.shrink(),
          editCondition: (filterId, newFilter, _) {
            final filter = newFilter as DateTimeFilter;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VSpace(4.0),
                if (filter.fieldType == FieldType.DateTime)
                  _DateTimeFilterIsStartSelector(
                    isStart: filter.condition.isStart,
                    onSelect: (newValue) {
                      final newFilter = filter.copyWithCondition(
                        isStart: newValue,
                        condition: filter.condition.toCondition(),
                      );
                      onSelect(newFilter);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FlowyText(
                    LocaleKeys.grid_filter_conditon.tr().toUpperCase(),
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
                  child: ListView.builder(
                    itemCount: DateTimeFilterCondition.values.length,
                    itemBuilder: (context, index) {
                      final condition = DateTimeFilterCondition.values[index];
                      return FlowyOptionTile.checkbox(
                        text: condition.filterName,
                        showTopBorder: false,
                        isSelected: filter.condition.toCondition() == condition,
                        onTap: () {
                          final newFilter = filter.copyWithCondition(
                            isStart: filter.condition.isStart,
                            condition: condition,
                          );
                          onSelect(newFilter);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DateTimeFilterIsStartSelector extends StatelessWidget {
  const _DateTimeFilterIsStartSelector({
    required this.isStart,
    required this.onSelect,
  });

  final bool isStart;
  final void Function(bool isStart) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: DefaultTabController(
        length: 2,
        initialIndex: isStart ? 0 : 1,
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
            onTap: (index) => onSelect(index == 0),
            tabs: [
              _tab(LocaleKeys.grid_dateFilter_startDate.tr()),
              _tab(LocaleKeys.grid_dateFilter_endDate.tr()),
            ],
          ),
        ),
      ),
    );
  }

  Tab _tab(String name) {
    return Tab(
      height: 34,
      child: Center(
        child: FlowyText(
          name,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _FilterContentEditor extends StatelessWidget {
  const _FilterContentEditor({
    required this.filter,
    required this.onUpdateFilter,
  });

  final DatabaseFilter filter;
  final void Function(DatabaseFilter) onUpdateFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterEditorBloc, FilterEditorState>(
      builder: (context, state) {
        final field = state.fields
            .firstWhereOrNull((field) => field.id == filter.fieldId);
        if (field == null) return const SizedBox.shrink();
        return switch (field.fieldType) {
          FieldType.SingleSelect ||
          FieldType.MultiSelect =>
            _SelectOptionFilterContentEditor(
              filter: filter as SelectOptionFilter,
              field: field,
            ),
          FieldType.DateTime =>
            _DateTimeFilterContentEditor(filter: filter as DateTimeFilter),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _SelectOptionFilterContentEditor extends StatefulWidget {
  _SelectOptionFilterContentEditor({
    required this.filter,
    required this.field,
  }) : delegate = filter.makeDelegate(field);

  final SelectOptionFilter filter;
  final FieldInfo field;
  final SelectOptionFilterDelegate delegate;

  @override
  State<_SelectOptionFilterContentEditor> createState() =>
      _SelectOptionFilterContentEditorState();
}

class _SelectOptionFilterContentEditorState
    extends State<_SelectOptionFilterContentEditor> {
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.delegate.getOptions(widget.field);
    return Column(
      children: [
        const Divider(
          height: 0.5,
          thickness: 0.5,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FlowyMobileSearchTextField(
            controller: textController,
            onChanged: (asdf) {},
            onSubmitted: (asdf) {},
            hintText: LocaleKeys.grid_selectOption_searchOption.tr(),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            separatorBuilder: (context, index) => const VSpace(20),
            itemCount: options.length,
            itemBuilder: (context, index) {
              return MobileSelectOption(
                option: options[index],
                isSelected: widget.filter.optionIds.contains(options[index].id),
                onTap: (isSelected) {
                  _onTapHandler(
                    context,
                    options,
                    options[index],
                    isSelected,
                  );
                },
                indicator: _getIndicator(),
                showMoreOptionsButton: false,
              );
            },
          ),
        ),
      ],
    );
  }

  MobileSelectedOptionIndicator _getIndicator() {
    return widget.filter.condition == SelectOptionFilterConditionPB.OptionIs &&
            widget.field.fieldType == FieldType.SingleSelect
        ? MobileSelectedOptionIndicator.single
        : MobileSelectedOptionIndicator.multi;
  }

  void _onTapHandler(
    BuildContext context,
    List<SelectOptionPB> options,
    SelectOptionPB option,
    bool isSelected,
  ) {
    if (isSelected) {
      final selectedOptionIds = Set<String>.from(widget.filter.optionIds)
        ..remove(option.id);

      _updateSelectOptions(context, options, selectedOptionIds);
    } else {
      final selectedOptionIds = widget.delegate.selectOption(
        widget.filter.optionIds,
        option.id,
        widget.filter.condition,
      );

      _updateSelectOptions(context, options, selectedOptionIds);
    }
  }

  void _updateSelectOptions(
    BuildContext context,
    List<SelectOptionPB> options,
    Set<String> selectedOptionIds,
  ) {
    final optionIds =
        options.map((e) => e.id).where(selectedOptionIds.contains).toList();
    final newFilter = widget.filter.copyWith(optionIds: optionIds);
    context.read<MobileFilterEditorCubit>().updateFilter(newFilter);
  }
}

class _DateTimeFilterContentEditor extends StatelessWidget {
  const _DateTimeFilterContentEditor({
    required this.filter,
  });

  final DateTimeFilter filter;

  @override
  Widget build(BuildContext context) {
    final isRange = filter.condition.isRange;
    return MobileDatePicker(
      isRange: isRange,
      selectedDay: isRange ? filter.start : filter.timestamp,
      startDay: isRange ? filter.start : null,
      endDay: isRange ? filter.end : null,
      onDaySelected: (selectedDay, _) {
        final newFilter = isRange
            ? filter.copyWithRange(start: selectedDay, end: null)
            : filter.copyWithTimestamp(timestamp: selectedDay);
        context.read<MobileFilterEditorCubit>().updateFilter(newFilter);
      },
      onRangeSelected: (start, end, _) {
        final newFilter = filter.copyWithRange(
          start: start,
          end: end,
        );
        context.read<MobileFilterEditorCubit>().updateFilter(newFilter);
      },
    );
  }
}
