import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../application/filter/text_filter_editor_bloc.dart';
import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';
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
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, TextFilterEditorState state) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          FlowyText(state.filterInfo.fieldInfo.name),
          const HSpace(4),
          TextFilterConditionPBList(
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
    BuildContext context,
    TextFilterEditorState state,
  ) {
    return FlowyTextField(
      text: state.filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      debounceDuration: const Duration(milliseconds: 300),
      autoFocus: false,
      onChanged: (text) {
        context
            .read<TextFilterEditorBloc>()
            .add(TextFilterEditorEvent.updateContent(text));
      },
    );
  }
}

class TextFilterConditionPBList extends StatelessWidget {
  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(TextFilterConditionPB) onCondition;
  const TextFilterConditionPBList({
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
  final TextFilterConditionPB inner;
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

extension TextFilterConditionPBExtension on TextFilterConditionPB {
  String get filterName {
    switch (this) {
      case TextFilterConditionPB.Contains:
        return LocaleKeys.grid_textFilter_contains.tr();
      case TextFilterConditionPB.DoesNotContain:
        return LocaleKeys.grid_textFilter_doesNotContain.tr();
      case TextFilterConditionPB.EndsWith:
        return LocaleKeys.grid_textFilter_endsWith.tr();
      case TextFilterConditionPB.Is:
        return LocaleKeys.grid_textFilter_is.tr();
      case TextFilterConditionPB.IsNot:
        return LocaleKeys.grid_textFilter_isNot.tr();
      case TextFilterConditionPB.StartsWith:
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
      case TextFilterConditionPB.DoesNotContain:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterConditionPB.EndsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_endWith.tr();
      case TextFilterConditionPB.IsNot:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterConditionPB.StartsWith:
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
