import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/board/application/hidden_groups_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HiddenGroupsColumn extends StatefulWidget {
  const HiddenGroupsColumn({super.key});

  @override
  State<HiddenGroupsColumn> createState() => _HiddenGroupsColumnState();
}

class _HiddenGroupsColumnState extends State<HiddenGroupsColumn> {
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final databaseController = context.read<BoardBloc>().databaseController;
    return AnimatedSize(
      alignment: AlignmentDirectional.topStart,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 150),
      child: isCollapsed
          ? Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
              child: _collapseExpandIcon(),
            )
          : SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FlowyText.medium(
                            'Hidden groups',
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        _collapseExpandIcon(),
                      ],
                    ),
                  ),
                  // cards
                  Expanded(
                    child:
                        HiddenGroupList(databaseController: databaseController),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _collapseExpandIcon() {
    return FlowyTooltip(
      message: isCollapsed ? "Expand group" : "Collpase group",
      child: FlowyIconButton(
        width: 20,
        height: 20,
        icon: FlowySvg(
          isCollapsed
              ? FlowySvgs.hamburger_s_s
              : FlowySvgs.pull_left_outlined_s,
        ),
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        onPressed: () => setState(() {
          isCollapsed = !isCollapsed;
        }),
      ),
    );
  }
}

class HiddenGroupList extends StatelessWidget {
  final DatabaseController databaseController;
  const HiddenGroupList({super.key, required this.databaseController});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HiddenGroupsBloc(
        databaseController: databaseController,
        initialHiddenGroups: context.read<BoardBloc>().hiddenGroups,
      )..add(const HiddenGroupsEvent.initial()),
      child: BlocBuilder<HiddenGroupsBloc, HiddenGroupsState>(
        builder: (context, state) {
          return ListView.separated(
            itemCount: state.hiddenGroups.length,
            itemBuilder: (context, index) => HiddenGroupCard(
              group: state.hiddenGroups[index],
            ),
            separatorBuilder: (context, index) => const VSpace(4),
          );
        },
      ),
    );
  }
}

class HiddenGroupCard extends StatefulWidget {
  final GroupPB group;
  const HiddenGroupCard({super.key, required this.group});

  @override
  State<HiddenGroupCard> createState() => _HiddenGroupCardState();
}

class _HiddenGroupCardState extends State<HiddenGroupCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: FlowyHover(
        resetHoverOnRebuild: false,
        builder: (context, isHovering) {
          return SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  // Opacity(
                  //   opacity: isHover ? 1 : 0,
                  //   child: const HiddenGroupCardActions(),
                  // ),
                  // const HSpace(4),
                  FlowyText.medium(
                    widget.group.groupName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const HSpace(6),
                  Expanded(
                    child: FlowyText.medium(
                      widget.group.rows.length.toString(),
                      overflow: TextOverflow.ellipsis,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  FlowyIconButton(
                    width: 20,
                    icon: isHovering
                        ? FlowySvg(
                            FlowySvgs.show_m,
                            color: Theme.of(context).hintColor,
                          )
                        : const SizedBox.shrink(),
                    onPressed: () {
                      context.read<BoardBloc>().add(
                            BoardEvent.toggleGroupVisibility(
                              widget.group.groupId,
                              true,
                            ),
                          );
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HiddenGroupCardActions extends StatelessWidget {
  const HiddenGroupCardActions({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      width: 14,
      child: FlowySvg(
        FlowySvgs.drag_element_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}
