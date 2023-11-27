import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/board/board.dart';
import 'package:appflowy/mobile/presentation/database/board/widgets/group_card_header.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileBoardContent extends StatefulWidget {
  const MobileBoardContent({
    super.key,
    this.onEditStateChanged,
  });

  final VoidCallback? onEditStateChanged; //**??? what is this for?

  @override
  State<MobileBoardContent> createState() => _MobileBoardContentState();
}

class _MobileBoardContentState extends State<MobileBoardContent> {
  final renderHook = RowCardRenderHook<String>();
  late final ScrollController scrollController;
  late final AppFlowyBoardScrollController scrollManager;

  @override
  void initState() {
    super.initState();
    //mobile may not need this
    //scroll to bottom when add a new card
    scrollManager = AppFlowyBoardScrollController();
    scrollController = ScrollController();
    renderHook.addSelectOptionHook((options, groupId, _) {
      // The cell should hide if the option id is equal to the groupId.
      final isInGroup =
          options.where((element) => element.id == groupId).isNotEmpty;

      if (isInGroup || options.isEmpty) {
        return const SizedBox.shrink();
      }

      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final config = AppFlowyBoardConfig(
      groupCornerRadius: 8,
      groupBackgroundColor: Theme.of(context).colorScheme.secondary,
      groupMargin: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      groupHeaderPadding: const EdgeInsets.all(8),
      groupBodyPadding: const EdgeInsets.all(4),
      groupFooterPadding: const EdgeInsets.all(8),
      cardMargin: const EdgeInsets.all(4),
    );

    return BlocListener<BoardBloc, BoardState>(
      listenWhen: (previous, current) =>
          previous.recentAddedRowMeta != current.recentAddedRowMeta,
      listener: (context, state) {
        // when add a new card
        // it push to the card detail screen of the new card
        final rowCache = context.read<BoardBloc>().getRowCache()!;
        context.push(
          MobileCardDetailScreen.routeName,
          extra: {
            MobileCardDetailScreen.argRowController: RowController(
              rowMeta: state.recentAddedRowMeta!,
              viewId: state.viewId,
              rowCache: rowCache,
            ),
          },
        );
      },
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          final showCreateGroupButton =
              context.read<BoardBloc>().groupingFieldType.canCreateNewGroup;
          final showHiddenGroups = state.hiddenGroups.isNotEmpty;
          return AppFlowyBoard(
            boardScrollController: scrollManager,
            scrollController: scrollController,
            controller: context.read<BoardBloc>().boardController,
            groupConstraints: BoxConstraints.tightFor(width: screenWidth * 0.7),
            config: config,
            leading: showHiddenGroups
                ? MobileHiddenGroupsColumn(margin: config.groupHeaderPadding)
                : const HSpace(16),
            trailing: showCreateGroupButton
                ? const MobileBoardTrailing()
                : const HSpace(16),
            headerBuilder: (_, groupData) => BlocProvider<BoardBloc>.value(
              value: context.read<BoardBloc>(),
              child: GroupCardHeader(
                groupData: groupData,
              ),
            ),
            footerBuilder: _buildFooter,
            cardBuilder: (_, column, columnItem) => _buildCard(
              context: context,
              afGroupData: column,
              afGroupItem: columnItem,
              cardMargin: config.cardMargin,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppFlowyGroupData columnData) {
    final style = Theme.of(context);

    return SizedBox(
      height: 42,
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.only(left: 8),
          alignment: Alignment.centerLeft,
        ),
        icon: FlowySvg(
          FlowySvgs.add_m,
          color: style.colorScheme.onSurface,
        ),
        label: Text(
          LocaleKeys.board_column_createNewCard.tr(),
          style: style.textTheme.bodyMedium?.copyWith(
            color: style.colorScheme.onSurface,
          ),
        ),
        onPressed: () => context.read<BoardBloc>()
          ..add(BoardEvent.createBottomRow(columnData.id)),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required AppFlowyGroupData afGroupData,
    required AppFlowyGroupItem afGroupItem,
    required EdgeInsets cardMargin,
  }) {
    final boardBloc = context.read<BoardBloc>();
    final groupItem = afGroupItem as GroupItem;
    final groupData = afGroupData.customData as GroupData;
    final rowMeta = groupItem.row;
    final rowCache = boardBloc.getRowCache();

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return SizedBox.shrink(key: ObjectKey(groupItem));
    final cellCache = rowCache.cellCache;
    final fieldController = boardBloc.fieldController;
    final viewId = boardBloc.viewId;

    final cellBuilder = CardCellBuilder<String>(cellCache);
    final isEditing = boardBloc.state.isEditingRow &&
        boardBloc.state.editingRow?.row.id == groupItem.row.id;

    final groupItemId = groupItem.row.id + groupData.group.groupId;

    return Container(
      key: ValueKey(groupItemId),
      margin: cardMargin,
      decoration: _makeBoxDecoration(context),
      child: RowCard<String>(
        rowMeta: rowMeta,
        viewId: viewId,
        rowCache: rowCache,
        cardData: groupData.group.groupId,
        groupingFieldId: groupItem.fieldInfo.id,
        groupId: groupData.group.groupId,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        renderHook: renderHook,
        openCard: (context) => _openCard(
          context: context,
          viewId: viewId,
          groupId: groupData.group.groupId,
          fieldController: fieldController,
          rowMeta: rowMeta,
          rowCache: rowCache,
        ),
        onStartEditing: () => boardBloc
            .add(BoardEvent.startEditingRow(groupData.group, groupItem.row)),
        onEndEditing: () =>
            boardBloc.add(BoardEvent.endEditingRow(groupItem.row.id)),
        styleConfiguration: const RowCardStyleConfiguration(
          showAccessory: false,
          hoverStyle: null,
          cardPadding: EdgeInsets.all(8),
          cellPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.fromBorderSide(
        BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      boxShadow: [
        // card shadow
        BoxShadow(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  void _openCard({
    required BuildContext context,
    required String viewId,
    required String groupId,
    required FieldController fieldController,
    required RowMetaPB rowMeta,
    required RowCache rowCache,
  }) {
    final rowInfo = RowInfo(
      viewId: viewId,
      fields: UnmodifiableListView(fieldController.fieldInfos),
      rowMeta: rowMeta,
      rowId: rowMeta.id,
    );

    final dataController = RowController(
      rowMeta: rowInfo.rowMeta,
      viewId: rowInfo.viewId,
      rowCache: rowCache,
      groupId: groupId,
    );

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      // To avoid the appbar of [MobileCardDetailScreen] being covered by status bar.
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        minChildSize: 0.4,
        snapSizes: const [0.4, 1],
        snap: true,
        builder: (context, scrollController) {
          return MobileCardDetailScreen(
            rowController: dataController,
            scrollController: scrollController,
            isBottemSheet: true,
          );
        },
      ),
    );
  }
}
