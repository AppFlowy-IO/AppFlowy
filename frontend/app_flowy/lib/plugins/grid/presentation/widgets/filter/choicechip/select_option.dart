import 'package:app_flowy/plugins/grid/application/filter/select_option_filter_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/condition_button.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/disclosure_button.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/text_field.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../generated/locale_keys.g.dart';
import 'choicechip.dart';

class SelectOptionFilterChoicechip extends StatefulWidget {
  final FilterInfo filterInfo;
  const SelectOptionFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  State<SelectOptionFilterChoicechip> createState() =>
      _SelectOptionFilterChoicechipState();
}

class _SelectOptionFilterChoicechipState
    extends State<SelectOptionFilterChoicechip> {
  late SelectOptionFilterEditorBloc bloc;

  @override
  void initState() {
    bloc = SelectOptionFilterEditorBloc(filterInfo: widget.filterInfo)
      ..add(const SelectOptionFilterEditorEvent.initial());
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
      child: BlocBuilder<SelectOptionFilterEditorBloc,
          SelectOptionFilterEditorState>(
        builder: (blocContext, state) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext context) {
              return Container();
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

  String _makeFilterDesc(SelectOptionFilterEditorState state) {
    return "123";
  }
}

class SelectOptionFilterEditor extends StatefulWidget {
  final SelectOptionFilterEditorBloc bloc;
  const SelectOptionFilterEditor({required this.bloc, Key? key})
      : super(key: key);

  @override
  State<SelectOptionFilterEditor> createState() =>
      _SelectOptionFilterEditorState();
}

class _SelectOptionFilterEditorState extends State<SelectOptionFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<SelectOptionFilterEditorBloc,
          SelectOptionFilterEditorState>(
        builder: (context, state) {
          final List<Widget> children = [
            _buildFilterPannel(context, state),
          ];

          if (state.filter.condition != SelectOptionCondition.OptionIsEmpty &&
              state.filter.condition !=
                  SelectOptionCondition.OptionIsNotEmpty) {
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

  Widget _buildFilterPannel(
      BuildContext context, SelectOptionFilterEditorState state) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          FlowyText(state.filterInfo.field.name),
          const HSpace(4),
          SelectOptionFilterConditionList(
            filterInfo: state.filterInfo,
            popoverMutex: popoverMutex,
            onCondition: (condition) {
              context.read<SelectOptionFilterEditorBloc>().add(
                  SelectOptionFilterEditorEvent.updateCondition(condition));
            },
          ),
          const Spacer(),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<SelectOptionFilterEditorBloc>()
                      .add(const SelectOptionFilterEditorEvent.delete());
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField(
      BuildContext context, SelectOptionFilterEditorState state) {
    return FilterTextField(
      text: "",
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      autoFucous: false,
      onSubmitted: (text) {
        context
            .read<SelectOptionFilterEditorBloc>()
            .add(const SelectOptionFilterEditorEvent.updateContent([]));
      },
    );
  }
}

class SelectOptionFilterConditionList extends StatelessWidget {
  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(SelectOptionCondition) onCondition;
  const SelectOptionFilterConditionList({
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectOptionFilter = filterInfo.selectOptionFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: SelectOptionCondition.values
          .map(
            (action) => ConditionWrapper(
              action,
              selectOptionFilter.condition == action,
              filterInfo.field.fieldType,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filterName(selectOptionFilter),
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        onCondition(action.inner);
        controller.close();
      },
    );
  }

  String filterName(SelectOptionFilterPB filter) {
    if (filterInfo.field.fieldType == FieldType.SingleSelect) {
      return filter.condition.singleSelectFilterName;
    } else {
      return filter.condition.multiSelectFilterName;
    }
  }
}

class ConditionWrapper extends ActionCell {
  final SelectOptionCondition inner;
  final bool isSelected;
  final FieldType fieldType;

  ConditionWrapper(this.inner, this.isSelected, this.fieldType);

  @override
  Widget? rightIcon(Color iconColor) {
    if (isSelected) {
      return svgWidget("grid/checkmark");
    } else {
      return null;
    }
  }

  @override
  String get name {
    if (fieldType == FieldType.SingleSelect) {
      return inner.singleSelectFilterName;
    } else {
      return inner.multiSelectFilterName;
    }
  }
}

extension SelectOptionConditionExtension on SelectOptionCondition {
  String get singleSelectFilterName {
    switch (this) {
      case SelectOptionCondition.OptionIs:
        return LocaleKeys.grid_singleSelectOptionFilter_is.tr();
      case SelectOptionCondition.OptionIsEmpty:
        return LocaleKeys.grid_singleSelectOptionFilter_isEmpty.tr();
      case SelectOptionCondition.OptionIsNot:
        return LocaleKeys.grid_singleSelectOptionFilter_isNot.tr();
      case SelectOptionCondition.OptionIsNotEmpty:
        return LocaleKeys.grid_singleSelectOptionFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }

  String get multiSelectFilterName {
    switch (this) {
      case SelectOptionCondition.OptionIs:
        return LocaleKeys.grid_multiSelectOptionFilter_contains.tr();
      case SelectOptionCondition.OptionIsEmpty:
        return LocaleKeys.grid_multiSelectOptionFilter_isEmpty.tr();
      case SelectOptionCondition.OptionIsNot:
        return LocaleKeys.grid_multiSelectOptionFilter_doesNotContain.tr();
      case SelectOptionCondition.OptionIsNotEmpty:
        return LocaleKeys.grid_multiSelectOptionFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }
}
