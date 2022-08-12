// ignore_for_file: unused_field

import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              key: UniqueKey(),
              dataController: context.read<BoardBloc>().boardDataController,
              headerBuilder: _buildHeader,
              footBuilder: _buildFooter,
              cardBuilder: _buildCard,
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

  Widget _buildHeader(BuildContext context, AFBoardColumnData columnData) {
    return AppFlowyColumnHeader(
      icon: const Icon(Icons.lightbulb_circle),
      title: Text(columnData.desc),
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
    );
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

    return AppFlowyColumnItemCard(
      key: ObjectKey(item),
      child: BoardCard(
        cellBuilder: cellBuilder,
        dataController: cardController,
        gridId: gridId,
      ),
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
