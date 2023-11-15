import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database_view/board/presentation/widgets/board_hidden_groups.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//TODO(yijing): refactor for mobile
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

  final config = const AppFlowyBoardConfig(
    groupBackgroundColor: Colors.green,
    headerPadding: EdgeInsets.symmetric(horizontal: 8),
    cardPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    groupPadding: EdgeInsets.symmetric(horizontal: 4),
    groupItemPadding: EdgeInsets.symmetric(horizontal: 4),
  );

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
    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) {
        _handleEditStateChanged(state, context);
        widget.onEditStateChanged?.call();
      },
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          final showCreateGroupButton =
              context.read<BoardBloc>().groupingFieldType.canCreateNewGroup;
          return Container(
            color: Colors.amber,
            child: AppFlowyBoard(
              boardScrollController: scrollManager,
              scrollController: scrollController,
              controller: context.read<BoardBloc>().boardController,
              groupConstraints: const BoxConstraints.tightFor(width: 300),
              config: config,
              leading: HiddenGroupsColumn(margin: config.headerPadding),
              trailing: showCreateGroupButton
                  ? BoardTrailing(scrollController: scrollController)
                  : null,
              headerBuilder: (_, groupData) => BlocProvider<BoardBloc>.value(
                value: context.read<BoardBloc>(),
                child: BoardColumnHeader(
                  groupData: groupData,
                  margin: config.headerPadding,
                ),
              ),
              footerBuilder: _buildFooter,
              cardBuilder: (_, column, columnItem) => _buildCard(
                context,
                column,
                columnItem,
              ),
            ),
          );
        },
      ),
    );
  }

  /// when add a new card, it got trigger
  /// todo refactor
  void _handleEditStateChanged(BoardState state, BuildContext context) {
    if (state.isEditingRow && state.editingRow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.editingRow!.index == null) {
          scrollManager.scrollToBottom(state.editingRow!.group.groupId);
        }
      });
    }
  }

  Widget _buildFooter(BuildContext context, AppFlowyGroupData columnData) {
    return AppFlowyGroupFooter(
      height: 50,
      margin: config.footerPadding,
      icon: SizedBox(
        height: 20,
        width: 20,
        child: FlowySvg(
          FlowySvgs.add_s,
          color: Theme.of(context).hintColor,
        ),
      ),
      title: FlowyText.medium(
        LocaleKeys.board_column_createNewCard.tr(),
        color: Theme.of(context).hintColor,
        fontSize: 14,
      ),
      onAddButtonClick: () => context
          .read<BoardBloc>()
          .add(BoardEvent.createBottomRow(columnData.id)),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppFlowyGroupData afGroupData,
    AppFlowyGroupItem afGroupItem,
  ) {
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

    return AppFlowyGroupCard(
      key: ValueKey(groupItemId),
      margin: config.cardPadding,
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
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      border: Border.fromBorderSide(
        BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1.4,
        ),
      ),
      boxShadow: [
        BoxShadow(
          blurRadius: 4,
          spreadRadius: 0,
          color: const Color(0xFF1F2329).withOpacity(0.02),
        ),
        BoxShadow(
          blurRadius: 4,
          spreadRadius: -2,
          color: const Color(0xFF1F2329).withOpacity(0.02),
        ),
      ],
    );
  }

  //TODO(yijing): connect to card detail PR
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

    FlowyOverlay.show(
      context: context,
      builder: (_) => RowDetailPage(
        cellBuilder: GridCellBuilder(cellCache: dataController.cellCache),
        rowController: dataController,
      ),
    );
  }
}
