// ignore_for_file: unused_field

import 'dart:collection';

import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/row/row_detail.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../grid/application/row/row_cache.dart';
import '../application/board_bloc.dart';
import 'card/card.dart';
import 'card/card_cell_builder.dart';

class BoardPage extends StatelessWidget {
  final ViewPB view;
  BoardPage({required this.view, Key? key}) : super(key: ValueKey(view.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BoardBloc(view: view)..add(const BoardEvent.initial()),
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) {
              return result.successOrFail.fold(
                (_) => BoardContent(),
                (err) => FlowyErrorPage(err.toString()),
              );
            },
          );
        },
      ),
    );
  }
}

class BoardContent extends StatelessWidget {
  final config = AFBoardConfig(
    columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
  );

  BoardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        return Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: AFBoard(
              scrollController: ScrollController(),
              dataController: context.read<BoardBloc>().boardController,
              headerBuilder: _buildHeader,
              footBuilder: _buildFooter,
              cardBuilder: (_, data) => _buildCard(context, data),
              columnConstraints: const BoxConstraints.tightFor(width: 240),
              config: AFBoardConfig(
                columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, AFBoardColumnHeaderData headerData) {
    return AppFlowyColumnHeader(
      icon: const Icon(Icons.lightbulb_circle),
      title: Text(headerData.columnName),
      addIcon: const Icon(Icons.add, size: 20),
      moreIcon: const Icon(Icons.more_horiz, size: 20),
      height: 50,
      margin: config.columnItemPadding,
    );
  }

  Widget _buildFooter(BuildContext context, AFBoardColumnData columnData) {
    return AppFlowyColumnFooter(
        icon: const Icon(Icons.add, size: 20),
        title: const Text('New'),
        height: 50,
        margin: config.columnItemPadding,
        onAddButtonClick: () {
          context.read<BoardBloc>().add(BoardEvent.createRow(columnData.id));
        });
  }

  Widget _buildCard(BuildContext context, AFColumnItem item) {
    final rowPB = (item as BoardColumnItem).row;
    final rowCache = context.read<BoardBloc>().getRowCache(rowPB.blockId);

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return SizedBox(key: ObjectKey(item));

    final fieldCache = context.read<BoardBloc>().fieldCache;
    final gridId = context.read<BoardBloc>().gridId;
    final cardController = CardDataController(
      fieldCache: fieldCache,
      rowCache: rowCache,
      rowPB: rowPB,
    );

    final cellBuilder = BoardCellBuilder(cardController);
    final isEditing = context.read<BoardBloc>().state.editingRow.fold(
          () => false,
          (editingRow) => editingRow.id == rowPB.id,
        );

    return AppFlowyColumnItemCard(
      key: ObjectKey(item),
      child: BoardCard(
        gridId: gridId,
        isEditing: isEditing,
        cellBuilder: cellBuilder,
        dataController: cardController,
        onEditEditing: (rowId) {
          context.read<BoardBloc>().add(BoardEvent.endEditRow(rowId));
        },
        openCard: (context) => _openCard(
          gridId,
          fieldCache,
          rowPB,
          rowCache,
          context,
        ),
      ),
    );
  }

  void _openCard(String gridId, GridFieldCache fieldCache, RowPB rowPB,
      GridRowCache rowCache, BuildContext context) {
    final rowInfo = RowInfo(
      gridId: gridId,
      fields: UnmodifiableListView(fieldCache.fields),
      rowPB: rowPB,
    );

    final dataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldCache: fieldCache,
      rowCache: rowCache,
    );

    RowDetailPage(
      cellBuilder: GridCellBuilder(delegate: dataController),
      dataController: dataController,
    ).show(context);
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
