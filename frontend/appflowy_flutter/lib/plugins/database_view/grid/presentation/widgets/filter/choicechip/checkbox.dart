import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/checkbox_filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';
import 'choicechip.dart';

class CheckboxFilterChoicechip extends StatefulWidget {
  final FilterInfo filterInfo;
  const CheckboxFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  State<CheckboxFilterChoicechip> createState() =>
      _CheckboxFilterChoicechipState();
}

class _CheckboxFilterChoicechipState extends State<CheckboxFilterChoicechip> {
  late CheckboxFilterEditorBloc bloc;

  @override
  void initState() {
    bloc = CheckboxFilterEditorBloc(filterInfo: widget.filterInfo)
      ..add(const CheckboxFilterEditorEvent.initial());
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
      child: BlocBuilder<CheckboxFilterEditorBloc, CheckboxFilterEditorState>(
        builder: (blocContext, state) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext context) {
              return CheckboxFilterEditor(bloc: bloc);
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

  String _makeFilterDesc(CheckboxFilterEditorState state) {
    final prefix = LocaleKeys.grid_checkboxFilter_choicechipPrefix_is.tr();
    return "$prefix ${state.filter.condition.filterName}";
  }
}

class CheckboxFilterEditor extends StatefulWidget {
  final CheckboxFilterEditorBloc bloc;
  const CheckboxFilterEditor({required this.bloc, Key? key}) : super(key: key);

  @override
  State<CheckboxFilterEditor> createState() => _CheckboxFilterEditorState();
}

class _CheckboxFilterEditorState extends State<CheckboxFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<CheckboxFilterEditorBloc, CheckboxFilterEditorState>(
        builder: (context, state) {
          final List<Widget> children = [
            _buildFilterPanel(context, state),
          ];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: IntrinsicHeight(child: Column(children: children)),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    CheckboxFilterEditorState state,
  ) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          FlowyText(state.filterInfo.fieldInfo.name),
          const HSpace(4),
          CheckboxFilterConditionList(
            filterInfo: state.filterInfo,
            popoverMutex: popoverMutex,
            onCondition: (condition) {
              context
                  .read<CheckboxFilterEditorBloc>()
                  .add(CheckboxFilterEditorEvent.updateCondition(condition));
            },
          ),
          const Spacer(),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<CheckboxFilterEditorBloc>()
                      .add(const CheckboxFilterEditorEvent.delete());
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}

class CheckboxFilterConditionList extends StatelessWidget {
  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(CheckboxFilterConditionPB) onCondition;
  const CheckboxFilterConditionList({
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkboxFilter = filterInfo.checkboxFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: CheckboxFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              checkboxFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: checkboxFilter.condition.filterName,
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
  final CheckboxFilterConditionPB inner;
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

extension TextFilterConditionPBExtension on CheckboxFilterConditionPB {
  String get filterName {
    switch (this) {
      case CheckboxFilterConditionPB.IsChecked:
        return LocaleKeys.grid_checkboxFilter_isChecked.tr();
      case CheckboxFilterConditionPB.IsUnChecked:
        return LocaleKeys.grid_checkboxFilter_isUnchecked.tr();
      default:
        return "";
    }
  }
}
