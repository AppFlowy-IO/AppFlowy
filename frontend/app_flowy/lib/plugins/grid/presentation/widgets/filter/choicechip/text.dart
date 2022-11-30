import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/filter/text_filter_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/condition_button.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/disclosure_button.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'choicechip.dart';

class TextFilterChoicechip extends StatefulWidget {
  final FilterInfo filterInfo;
  const TextFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  State<TextFilterChoicechip> createState() => _TextFilterChoicechipState();
}

class _TextFilterChoicechipState extends State<TextFilterChoicechip> {
  late TextFilterEditorBloc bloc;

  @override
  void initState() {
    bloc = TextFilterEditorBloc(filterInfo: widget.filterInfo)
      ..add(const TextFilterEditorEvent.initial());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<TextFilterEditorBloc, TextFilterEditorState>(
        builder: (blocContext, state) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext context) {
              return TextFilterEditor(bloc: bloc);
            },
            child: ChoiceChipButton(
              filterInfo: widget.filterInfo,
              filterDesc: _makeFilterDesc(state),
            ),
          );
        },
      ),
    );
  }

  String _makeFilterDesc(TextFilterEditorState state) {
    String filterDesc = state.filter.condition.choicechipPrefix;
    if (state.filter.condition == TextFilterCondition.TextIsEmpty ||
        state.filter.condition == TextFilterCondition.TextIsNotEmpty) {
      return filterDesc;
    }

    if (state.filter.content.isNotEmpty) {
      filterDesc += " ${state.filter.content}";
    }

    return filterDesc;
  }
}

class TextFilterEditor extends StatefulWidget {
  final TextFilterEditorBloc bloc;
  const TextFilterEditor({required this.bloc, Key? key}) : super(key: key);

  @override
  State<TextFilterEditor> createState() => _TextFilterEditorState();
}

class _TextFilterEditorState extends State<TextFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<TextFilterEditorBloc, TextFilterEditorState>(
        builder: (context, state) {
          final List<Widget> children = [
            _buildFilterPannel(context, state),
          ];

          if (state.filter.condition != TextFilterCondition.TextIsEmpty &&
              state.filter.condition != TextFilterCondition.TextIsNotEmpty) {
            children.add(const VSpace(4));
            children.add(_buildFilterTextField(context, state));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: IntrinsicHeight(child: Column(children: children)),
          );
        },
      ),
    );
  }

  Widget _buildFilterPannel(BuildContext context, TextFilterEditorState state) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          FlowyText(state.filterInfo.fieldInfo.name),
          const HSpace(4),
          TextFilterConditionList(
            filterInfo: state.filterInfo,
            popoverMutex: popoverMutex,
            onCondition: (condition) {
              context
                  .read<TextFilterEditorBloc>()
                  .add(TextFilterEditorEvent.updateCondition(condition));
            },
          ),
          const Spacer(),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<TextFilterEditorBloc>()
                      .add(const TextFilterEditorEvent.delete());
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField(
      BuildContext context, TextFilterEditorState state) {
    return FlowyTextField(
      text: state.filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      autoFocus: false,
      onSubmitted: (text) {
        context
            .read<TextFilterEditorBloc>()
            .add(TextFilterEditorEvent.updateContent(text));
      },
    );
  }
}

class TextFilterConditionList extends StatelessWidget {
  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(TextFilterCondition) onCondition;
  const TextFilterConditionList({
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textFilter = filterInfo.textFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: TextFilterCondition.values
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
  final TextFilterCondition inner;
  final bool isSelected;

  ConditionWrapper(this.inner, this.isSelected);

  @override
  Widget? rightIcon(Color iconColor) {
    if (isSelected) {
      return svgWidget("grid/checkmark");
    } else {
      return null;
    }
  }

  @override
  String get name => inner.filterName;
}

extension TextFilterConditionExtension on TextFilterCondition {
  String get filterName {
    switch (this) {
      case TextFilterCondition.Contains:
        return LocaleKeys.grid_textFilter_contains.tr();
      case TextFilterCondition.DoesNotContain:
        return LocaleKeys.grid_textFilter_doesNotContain.tr();
      case TextFilterCondition.EndsWith:
        return LocaleKeys.grid_textFilter_endsWith.tr();
      case TextFilterCondition.Is:
        return LocaleKeys.grid_textFilter_is.tr();
      case TextFilterCondition.IsNot:
        return LocaleKeys.grid_textFilter_isNot.tr();
      case TextFilterCondition.StartsWith:
        return LocaleKeys.grid_textFilter_startWith.tr();
      case TextFilterCondition.TextIsEmpty:
        return LocaleKeys.grid_textFilter_isEmpty.tr();
      case TextFilterCondition.TextIsNotEmpty:
        return LocaleKeys.grid_textFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }

  String get choicechipPrefix {
    switch (this) {
      case TextFilterCondition.DoesNotContain:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterCondition.EndsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_endWith.tr();
      case TextFilterCondition.IsNot:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterCondition.StartsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_startWith.tr();
      case TextFilterCondition.TextIsEmpty:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isEmpty.tr();
      case TextFilterCondition.TextIsNotEmpty:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNotEmpty.tr();
      default:
        return "";
    }
  }
}
