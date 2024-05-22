import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/text_card_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileHiddenGroupsColumn extends StatelessWidget {
  const MobileHiddenGroupsColumn({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final databaseController = context.read<BoardBloc>().databaseController;
    return BlocSelector<BoardBloc, BoardState, BoardLayoutSettingPB?>(
      selector: (state) => state.maybeMap(
        orElse: () => null,
        ready: (value) => value.layoutSettings,
      ),
      builder: (context, layoutSettings) {
        if (layoutSettings == null) {
          return const SizedBox.shrink();
        }
        final isCollapsed = layoutSettings.collapseHiddenGroups;
        return Container(
          padding: padding,
          child: AnimatedSize(
            alignment: AlignmentDirectional.topStart,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 150),
            child: isCollapsed
                ? SizedBox(
                    height: 50,
                    child: _collapseExpandIcon(context, isCollapsed),
                  )
                : SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            _collapseExpandIcon(context, isCollapsed),
                          ],
                        ),
                        Text(
                          LocaleKeys.board_hiddenGroupSection_sectionTitle.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                        const VSpace(8),
                        Expanded(
                          child: MobileHiddenGroupList(
                            databaseController: databaseController,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _collapseExpandIcon(BuildContext context, bool isCollapsed) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: IconButton(
        icon: FlowySvg(
          isCollapsed
              ? FlowySvgs.hamburger_s_s
              : FlowySvgs.pull_left_outlined_s,
          size: isCollapsed ? const Size.square(12) : const Size.square(40),
        ),
        onPressed: () => context
            .read<BoardBloc>()
            .add(BoardEvent.toggleHiddenSectionVisibility(!isCollapsed)),
      ),
    );
  }
}

class MobileHiddenGroupList extends StatelessWidget {
  const MobileHiddenGroupList({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (_, state) {
        return state.maybeMap(
          orElse: () => const SizedBox.shrink(),
          ready: (state) {
            return ReorderableListView.builder(
              itemCount: state.hiddenGroups.length,
              itemBuilder: (_, index) => MobileHiddenGroup(
                key: ValueKey(state.hiddenGroups[index].groupId),
                group: state.hiddenGroups[index],
                index: index,
              ),
              proxyDecorator: (child, index, animation) => BlocProvider.value(
                value: context.read<BoardBloc>(),
                child: Material(color: Colors.transparent, child: child),
              ),
              physics: const ClampingScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex--;
                }
                final fromGroupId = state.hiddenGroups[oldIndex].groupId;
                final toGroupId = state.hiddenGroups[newIndex].groupId;
                context
                    .read<BoardBloc>()
                    .add(BoardEvent.reorderGroup(fromGroupId, toGroupId));
              },
            );
          },
        );
      },
    );
  }
}

class MobileHiddenGroup extends StatelessWidget {
  const MobileHiddenGroup({
    super.key,
    required this.group,
    required this.index,
  });

  final GroupPB group;
  final int index;

  @override
  Widget build(BuildContext context) {
    final databaseController = context.read<BoardBloc>().databaseController;
    final primaryField = databaseController.fieldController.fieldInfos
        .firstWhereOrNull((element) => element.isPrimary)!;

    final cells = group.rows.map(
      (item) {
        final cellContext =
            databaseController.rowCache.loadCells(item).firstWhere(
                  (cellContext) => cellContext.fieldId == primaryField.id,
                );

        return TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.bodyMedium,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            visualDensity: VisualDensity.compact,
          ),
          child: CardCellBuilder(
            databaseController: context.read<BoardBloc>().databaseController,
          ).build(
            cellContext: cellContext,
            styleMap: {FieldType.RichText: _titleCellStyle(context)},
            hasNotes: !item.isDocumentEmpty,
          ),
          onPressed: () {
            context.push(
              MobileRowDetailPage.routeName,
              extra: {
                MobileRowDetailPage.argRowId: item.id,
                MobileRowDetailPage.argDatabaseController:
                    context.read<BoardBloc>().databaseController,
              },
            );
          },
        );
      },
    ).toList();

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(
              context.read<BoardBloc>().generateGroupNameFromGroup(group),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: FlowySvg(
                FlowySvgs.hide_m,
                size: Size.square(20),
              ),
            ),
            onTap: () => showFlowyMobileConfirmDialog(
              context,
              title: FlowyText(LocaleKeys.board_mobile_showGroup.tr()),
              content: FlowyText(
                LocaleKeys.board_mobile_showGroupContent.tr(),
              ),
              actionButtonTitle: LocaleKeys.button_yes.tr(),
              actionButtonColor: Theme.of(context).colorScheme.primary,
              onActionButtonPressed: () => context
                  .read<BoardBloc>()
                  .add(BoardEvent.setGroupVisibility(group, true)),
            ),
          ),
        ],
      ),
      children: cells,
    );
  }

  TextCardCellStyle _titleCellStyle(BuildContext context) {
    return TextCardCellStyle(
      padding: EdgeInsets.zero,
      textStyle: Theme.of(context).textTheme.bodyMedium!,
      maxLines: 2,
      titleTextStyle: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(fontSize: 11, overflow: TextOverflow.ellipsis),
    );
  }
}
