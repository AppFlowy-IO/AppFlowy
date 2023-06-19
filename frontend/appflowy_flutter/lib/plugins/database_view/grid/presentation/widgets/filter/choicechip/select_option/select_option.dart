import 'package:appflowy/plugins/database_view/grid/application/filter/select_option_filter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../disclosure_button.dart';
import '../../filter_info.dart';
import '../choicechip.dart';
import 'condition_list.dart';
import 'option_list.dart';
import 'select_option_loader.dart';

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
    if (widget.filterInfo.fieldInfo.fieldType == FieldType.SingleSelect) {
      bloc = SelectOptionFilterEditorBloc(
        filterInfo: widget.filterInfo,
        delegate: SingleSelectOptionFilterDelegateImpl(widget.filterInfo),
      );
    } else {
      bloc = SelectOptionFilterEditorBloc(
        filterInfo: widget.filterInfo,
        delegate: MultiSelectOptionFilterDelegateImpl(widget.filterInfo),
      );
    }
    bloc.add(const SelectOptionFilterEditorEvent.initial());
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
            constraints: BoxConstraints.loose(const Size(240, 160)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext context) {
              return SelectOptionFilterEditor(bloc: bloc);
            },
            child: ChoiceChipButton(
              filterInfo: widget.filterInfo,
              filterDesc: state.filterDesc,
            ),
          );
        },
      ),
    );
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
          final List<Widget> slivers = [
            SliverToBoxAdapter(child: _buildFilterPanel(context, state)),
          ];

          if (state.filter.condition != SelectOptionConditionPB.OptionIsEmpty &&
              state.filter.condition !=
                  SelectOptionConditionPB.OptionIsNotEmpty) {
            slivers.add(const SliverToBoxAdapter(child: VSpace(4)));
            slivers.add(
              SliverToBoxAdapter(
                child: SelectOptionFilterList(
                  filterInfo: state.filterInfo,
                  selectedOptionIds: state.filter.optionIds,
                  onSelectedOptions: (optionIds) {
                    context.read<SelectOptionFilterEditorBloc>().add(
                          SelectOptionFilterEditorEvent.updateContent(
                            optionIds,
                          ),
                        );
                  },
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: slivers,
              controller: ScrollController(),
              physics: StyledScrollPhysics(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    SelectOptionFilterEditorState state,
  ) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          FlowyText(state.filterInfo.fieldInfo.name),
          const HSpace(4),
          SelectOptionFilterConditionList(
            filterInfo: state.filterInfo,
            popoverMutex: popoverMutex,
            onCondition: (condition) {
              context.read<SelectOptionFilterEditorBloc>().add(
                    SelectOptionFilterEditorEvent.updateCondition(condition),
                  );
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
}
