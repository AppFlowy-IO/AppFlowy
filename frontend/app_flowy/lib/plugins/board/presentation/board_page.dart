// ignore_for_file: unused_field

import 'package:appflowy_board/appflowy_board.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/board_bloc.dart';

class BoardPage extends StatelessWidget {
  final ViewPB view;
  const BoardPage({required this.view, Key? key}) : super(key: key);

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
  final config = BoardConfig(
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
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Board(
              dataController: context.read<BoardBloc>().boardDataController,
              headerBuilder: _buildHeader,
              footBuilder: _buildFooter,
              cardBuilder: (context, item) {
                return AppFlowyColumnItemCard(
                  key: ObjectKey(item),
                  child: _buildCard(item),
                );
              },
              columnConstraints: const BoxConstraints.tightFor(width: 240),
              config: BoardConfig(
                columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BoardColumnData columnData) {
    return AppFlowyColumnHeader(
      icon: const Icon(Icons.lightbulb_circle),
      title: Text(columnData.desc),
      addIcon: const Icon(Icons.add, size: 20),
      moreIcon: const Icon(Icons.more_horiz, size: 20),
      height: 50,
      margin: config.columnItemPadding,
    );
  }

  Widget _buildFooter(BuildContext context, BoardColumnData columnData) {
    return AppFlowyColumnFooter(
      icon: const Icon(Icons.add, size: 20),
      title: const Text('New'),
      height: 50,
      margin: config.columnItemPadding,
    );
  }

  Widget _buildCard(ColumnItem item) {
    if (item is TextItem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(item.s),
        ),
      );
    }

    if (item is RichTextItem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 10),
              Text(
                item.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),
        ),
      );
    }

    throw UnimplementedError();
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
