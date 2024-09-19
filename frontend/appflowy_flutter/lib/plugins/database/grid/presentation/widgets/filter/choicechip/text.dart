import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/text_filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';

import 'choicechip.dart';

class TextFilterChoicechip extends StatelessWidget {
  const TextFilterChoicechip({
    super.key,
    required this.fieldController,
    required this.filterInfo,
  });

  final FieldController fieldController;
  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TextFilterBloc(
        fieldController: fieldController,
        filterInfo: filterInfo,
        fieldType: FieldType.RichText,
      ),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<TextFilterBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<FilterEditorBloc>(),
                  ),
                ],
                child: const TextFilterEditor(),
              );
            },
            child: BlocBuilder<TextFilterBloc, TextFilterState>(
              builder: (context, state) {
                return ChoiceChipButton(
                  filterInfo: state.filterInfo,
                  filterDesc: _makeFilterDesc(state),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _makeFilterDesc(TextFilterState state) {
    String filterDesc = state.filter.condition.choicechipPrefix;
    if (state.filter.condition == TextFilterConditionPB.TextIsEmpty ||
        state.filter.condition == TextFilterConditionPB.TextIsNotEmpty) {
      return filterDesc;
    }

    if (state.filter.content.isNotEmpty) {
      filterDesc += " ${state.filter.content}";
    }

    return filterDesc;
  }
}

class TextFilterEditor extends StatefulWidget {
  const TextFilterEditor({super.key});

  @override
  State<TextFilterEditor> createState() => _TextFilterEditorState();
}

class _TextFilterEditorState extends State<TextFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextFilterBloc, TextFilterState>(
      builder: (context, state) {
        final List<Widget> children = [
          _buildFilterPanel(context, state),
        ];

        if (state.filter.condition != TextFilterConditionPB.TextIsEmpty &&
            state.filter.condition != TextFilterConditionPB.TextIsNotEmpty) {
          children.add(const VSpace(4));
          children.add(_buildFilterTextField(context, state));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(child: Column(children: children)),
        );
      },
    );
  }

  Widget _buildFilterPanel(BuildContext context, TextFilterState state) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              state.filterInfo.fieldInfo.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4),
          Expanded(
            child: TextFilterConditionPBList(
              filterInfo: state.filterInfo,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                context
                    .read<TextFilterBloc>()
                    .add(TextFilterEvent.updateCondition(condition));
              },
            ),
          ),
          const HSpace(4),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context.read<FilterEditorBloc>().add(
                        FilterEditorEvent.deleteFilter(
                          state.filterInfo.filterId,
                        ),
                      );
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField(
    BuildContext context,
    TextFilterState state,
  ) {
    return FlowyTextField(
      text: state.filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      debounceDuration: const Duration(milliseconds: 300),
      autoFocus: false,
      onChanged: (text) {
        context.read<TextFilterBloc>().add(TextFilterEvent.updateContent(text));
      },
    );
  }
}

class TextFilterConditionPBList extends StatelessWidget {
  const TextFilterConditionPBList({
    super.key,
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
  });

  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(TextFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    final textFilter = filterInfo.textFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: TextFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              textFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: textFilter.condition.filterName,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        onCondition(action.inner);
        controller.close();
      },
    );
  }
}

class ConditionWrapper extends ActionCell {
  ConditionWrapper(this.inner, this.isSelected);

  final TextFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) {
    if (isSelected) {
      return const FlowySvg(FlowySvgs.check_s);
    } else {
      return null;
    }
  }

  @override
  String get name => inner.filterName;
}

extension TextFilterConditionPBExtension on TextFilterConditionPB {
  String get filterName {
    switch (this) {
      case TextFilterConditionPB.TextContains:
        return LocaleKeys.grid_textFilter_contains.tr();
      case TextFilterConditionPB.TextDoesNotContain:
        return LocaleKeys.grid_textFilter_doesNotContain.tr();
      case TextFilterConditionPB.TextEndsWith:
        return LocaleKeys.grid_textFilter_endsWith.tr();
      case TextFilterConditionPB.TextIs:
        return LocaleKeys.grid_textFilter_is.tr();
      case TextFilterConditionPB.TextIsNot:
        return LocaleKeys.grid_textFilter_isNot.tr();
      case TextFilterConditionPB.TextStartsWith:
        return LocaleKeys.grid_textFilter_startWith.tr();
      case TextFilterConditionPB.TextIsEmpty:
        return LocaleKeys.grid_textFilter_isEmpty.tr();
      case TextFilterConditionPB.TextIsNotEmpty:
        return LocaleKeys.grid_textFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }

  String get choicechipPrefix {
    switch (this) {
      case TextFilterConditionPB.TextDoesNotContain:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterConditionPB.TextEndsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_endWith.tr();
      case TextFilterConditionPB.TextIsNot:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterConditionPB.TextStartsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_startWith.tr();
      case TextFilterConditionPB.TextIsEmpty:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isEmpty.tr();
      case TextFilterConditionPB.TextIsNotEmpty:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNotEmpty.tr();
      default:
        return "";
    }
  }
}
