// ignore_for_file: unused_field

import 'dart:collection';

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/row/row_detail.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/board_bloc.dart';
import 'card/card.dart';
import 'card/card_cell_builder.dart';
import 'toolbar/board_toolbar.dart';

class BoardPage extends StatelessWidget {
  final ViewPB view;
  BoardPage({
    required this.view,
    Key? key,
  }) : super(key: ValueKey(view.id));

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
                (_) => const BoardContent(),
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
  const BoardContent({Key? key}) : super(key: key);

  @override
  State<BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends State<BoardContent> {
  late AppFlowyBoardScrollController scrollManager;

  final config = AppFlowyBoardConfig(
    groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
  );

  @override
  void initState() {
    scrollManager = AppFlowyBoardScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardBloc, BoardState>(
      listener: (context, state) => _handleEditStateChanged(state, context),
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
          color: Theme.of(context).colorScheme.onSurface,
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
          color: Theme.of(context).colorScheme.onSurface,
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
    final rowCache = context.read<BoardBloc>().getRowCache(rowPB.blockId);

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return SizedBox(key: ObjectKey(groupItem));

    final fieldController = context.read<BoardBloc>().fieldController;
    final gridId = context.read<BoardBloc>().gridId;
    final cardController = CardDataController(
      fieldController: fieldController,
      rowCache: rowCache,
      rowPB: rowPB,
    );

    final cellBuilder = BoardCellBuilder(cardController);
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
      child: BoardCard(
        gridId: gridId,
        groupId: groupData.group.groupId,
        fieldId: groupItem.fieldInfo.id,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        dataController: cardController,
        openCard: (context) => _openCard(
          gridId,
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
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.fromBorderSide(borderSide),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    );
  }

  void _openCard(
    String gridId,
    GridFieldController fieldController,
    RowPB rowPB,
    GridRowCache rowCache,
    BuildContext context,
  ) {
    final rowInfo = RowInfo(
      gridId: gridId,
      fields: UnmodifiableListView(fieldController.fieldInfos),
      rowPB: rowPB,
    );

    final dataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: fieldController,
      rowCache: rowCache,
    );

    FlowyOverlay.show(
      context: context,
      builder: (BuildContext context) {
        return RowDetailPage(
          cellBuilder: GridCellBuilder(delegate: dataController),
          dataController: dataController,
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
      builder: (context, state) {
        final bloc = context.read<BoardBloc>();
        final toolbarContext = BoardToolbarContext(
          viewId: bloc.gridId,
          fieldController: bloc.fieldController,
        );

        return BoardToolbar(toolbarContext: toolbarContext);
      },
    );
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
