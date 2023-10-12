import 'package:appflowy/plugins/database_view/application/filter/filter_info.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/select_option_filter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../disclosure_button.dart';
import '../choicechip.dart';
import 'condition_list.dart';
import 'option_list.dart';

class SelectOptionFilterChoicechip extends StatefulWidget {
  final String viewId;
  final FilterInfo filterInfo;
  const SelectOptionFilterChoicechip({
    required this.filterInfo,
    required this.viewId,
    super.key,
  });

  @override
  State<SelectOptionFilterChoicechip> createState() =>
      _SelectOptionFilterChoicechipState();
}

class _SelectOptionFilterChoicechipState
    extends State<SelectOptionFilterChoicechip> {
  late SelectOptionFilterEditorBloc bloc;

  @override
  void initState() {
    bloc = SelectOptionFilterEditorBloc(
      viewId: widget.viewId,
      filterInfo: widget.filterInfo,
    )..add(const SelectOptionFilterEditorEvent.initial());
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
              return SelectOptionFilterEditor(
                viewId: widget.viewId,
                bloc: bloc,
              );
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
  final String viewId;
  final SelectOptionFilterEditorBloc bloc;
  const SelectOptionFilterEditor({
    required this.viewId,
    required this.bloc,
    super.key,
  });

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
                  viewId: widget.viewId,
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
          Expanded(
            child: FlowyText(
              state.filterInfo.field.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
