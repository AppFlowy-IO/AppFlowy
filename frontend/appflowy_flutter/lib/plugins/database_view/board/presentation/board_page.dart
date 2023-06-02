// ignore_for_file: unused_field

import 'dart:collection';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/card/cells/card_cell.dart';
import '../../widgets/card/card_cell_builder.dart';
import '../../widgets/row/cell_builder.dart';
import '../application/board_bloc.dart';
import '../../widgets/card/card.dart';
import 'toolbar/board_toolbar.dart';

class BoardPage extends StatelessWidget {
  BoardPage({
    required this.view,
    Key? key,
    this.onEditStateChanged,
  }) : super(key: ValueKey(view.id));

  final ViewPB view;

  /// Called when edit state changed
  final VoidCallback? onEditStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BoardBloc(view: view)..add(const BoardEvent.initial()),
      child: BlocBuilder<BoardBloc, BoardState>(
        buildWhen: (p, c) => p.loadingState != c.loadingState,
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) {
              return result.successOrFail.fold(
                (_) => BoardContent(
                  onEditStateChanged: onEditStateChanged,
                ),
                (err) => FlowyErrorPage(err.toString()),
              );
            },
          );
        },
      ),
    );
  }
}

class BoardContent extends StatefulWidget {
  const BoardContent({
    Key? key,
    this.onEditStateChanged,
  }) : super(key: key);

  final VoidCallback? onEditStateChanged;

  @override
  State<BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<BoardContent> {
  late AppFlowyBoardScrollController scrollManager;
  final renderHook = RowCardRenderHook<String>();

  final config = const AppFlowyBoardConfig(
    groupBackgroundColor: Color(0xffF7F8FC),
  );

  @override
  void initState() {
    scrollManager = AppFlowyBoardScrollController();
    renderHook.addSelectOptionHook((options, groupId, _) {
      // The cell should hide if the option id is equal to the groupId.
      final isInGroup =
          options.where((element) => element.id == groupId).isNotEmpty;
      if (isInGroup || options.isEmpty) {
        return const SizedBox();
      }
      return null;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) {
        _handleEditStateChanged(state, context);
        widget.onEditStateChanged?.call();
      },
      child: BlocBuilder<BoardBloc, BoardState>(
        buildWhen: (previous, current) => previous.groupIds != current.groupIds,
        builder: (context, state) {
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const _ToolbarBlocAdaptor(), _buildBoard(context)],
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: column,
          );
        },
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    return Expanded(
      child: AppFlowyBoard(
        boardScrollController: scrollManager,
        scrollController: ScrollController(),
        controller: context.read<BoardBloc>().boardController,
        headerBuilder: _buildHeader,
        footerBuilder: _buildFooter,
        cardBuilder: (_, column, columnItem) => _buildCard(
          context,
          column,
          columnItem,
        ),
        groupConstraints: const BoxConstraints.tightFor(width: 300),
        config: AppFlowyBoardConfig(
          groupBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
    );
  }

  void _handleEditStateChanged(BoardState state, BuildContext context) {
    state.editingRow.fold(
      () => null,
      (editingRow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (editingRow.index != null) {
          } else {
            scrollManager.scrollToBottom(editingRow.group.groupId);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildHeader(
    BuildContext context,
    AppFlowyGroupData groupData,
  ) {
    final boardCustomData = groupData.customData as GroupData;
    return AppFlowyGroupHeader(
      title: Flexible(
        fit: FlexFit.tight,
        child: FlowyText.medium(
          groupData.headerData.groupName,
          fontSize: 14,
          overflow: TextOverflow.clip,
        ),
      ),
      icon: _buildHeaderIcon(boardCustomData),
      addIcon: SizedBox(
        height: 20,
        width: 20,
        child: svgWidget(
          "home/add",
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      onAddButtonClick: () {
        context.read<BoardBloc>().add(
              BoardEvent.createHeaderRow(groupData.id),
            );
      },
      height: 50,
      margin: config.headerPadding,
    );
  }

  Widget _buildFooter(BuildContext context, AppFlowyGroupData columnData) {
    // final boardCustomData = columnData.customData as BoardCustomData;
    // final group = boardCustomData.group;

    return AppFlowyGroupFooter(
      icon: SizedBox(
        height: 20,
        width: 20,
        child: svgWidget(
          "home/add",
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      title: FlowyText.medium(
        LocaleKeys.board_column_create_new_card.tr(),
        fontSize: 14,
      ),
      height: 50,
      margin: config.footerPadding,
      onAddButtonClick: () {
        context.read<BoardBloc>().add(
              BoardEvent.createBottomRow(columnData.id),
            );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppFlowyGroupData afGroupData,
    AppFlowyGroupItem afGroupItem,
  ) {
    final groupItem = afGroupItem as GroupItem;
    final groupData = afGroupData.customData as GroupData;
    final rowPB = groupItem.row;
    final rowCache = context.read<BoardBloc>().getRowCache();

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return SizedBox(key: ObjectKey(groupItem));
    final cellCache = rowCache.cellCache;
    final fieldController = context.read<BoardBloc>().fieldController;
    final viewId = context.read<BoardBloc>().viewId;

    final cellBuilder = CardCellBuilder<String>(cellCache);
    bool isEditing = false;
    context.read<BoardBloc>().state.editingRow.fold(
      () => null,
      (editingRow) {
        isEditing = editingRow.row.id == groupItem.row.id;
      },
    );

    final groupItemId = groupItem.row.id + groupData.group.groupId;
    return AppFlowyGroupCard(
      key: ValueKey(groupItemId),
      margin: config.cardPadding,
      decoration: _makeBoxDecoration(context),
      child: RowCard<String>(
        row: rowPB,
        viewId: viewId,
        rowCache: rowCache,
        cardData: groupData.group.groupId,
        groupingFieldId: groupItem.fieldInfo.id,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        renderHook: renderHook,
        openCard: (context) => _openCard(
          viewId,
          groupData.group.groupId,
          fieldController,
          rowPB,
          rowCache,
          context,
        ),
        onStartEditing: () {
          context.read<BoardBloc>().add(
                BoardEvent.startEditingRow(
                  groupData.group,
                  groupItem.row,
                ),
              );
        },
        onEndEditing: () {
          context
              .read<BoardBloc>()
              .add(BoardEvent.endEditingRow(groupItem.row.id));
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context) {
    final borderSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 1.0,
    );
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: isLightMode ? Border.fromBorderSide(borderSide) : null,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    );
  }

  void _openCard(
    String viewId,
    String groupId,
    FieldController fieldController,
    RowPB rowPB,
    RowCache rowCache,
    BuildContext context,
  ) {
    final rowInfo = RowInfo(
      viewId: viewId,
      fields: UnmodifiableListView(fieldController.fieldInfos),
      rowPB: rowPB,
    );

    final dataController = RowController(
      rowId: rowInfo.rowPB.id,
      viewId: rowInfo.viewId,
      rowCache: rowCache,
      groupId: groupId,
    );

    FlowyOverlay.show(
      context: context,
      builder: (BuildContext context) {
        return RowDetailPage(
          cellBuilder: GridCellBuilder(cellCache: dataController.cellCache),
          rowController: dataController,
        );
      },
    );
  }
}

class _ToolbarBlocAdaptor extends StatelessWidget {
  const _ToolbarBlocAdaptor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) => const BoardToolbar(),
    );
  }
}

Widget? _buildHeaderIcon(GroupData customData) {
  Widget? widget;
  switch (customData.fieldType) {
    case FieldType.Checkbox:
      final group = customData.asCheckboxGroup()!;
      if (group.isCheck) {
        widget = svgWidget('editor/editor_check');
      } else {
        widget = svgWidget('editor/editor_uncheck');
      }
      break;
    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      break;
    case FieldType.MultiSelect:
      break;
    case FieldType.Number:
      break;
    case FieldType.RichText:
      break;
    case FieldType.SingleSelect:
      break;
    case FieldType.URL:
      break;
    case FieldType.Checklist:
      break;
  }

  if (widget != null) {
    widget = SizedBox(
      width: 20,
      height: 20,
      child: widget,
    );
  }
  return widget;
}
