import 'package:flutter/material.dart';
import 'package:appflowy_board/appflowy_board.dart';

class SingleBoardListExample extends StatefulWidget {
  const SingleBoardListExample({Key? key}) : super(key: key);

  @override
  State<SingleBoardListExample> createState() => _SingleBoardListExampleState();
}

class _SingleBoardListExampleState extends State<SingleBoardListExample> {
  final AFBoardDataController boardData = AFBoardDataController();

  @override
  void initState() {
    final column = AFBoardColumnData(
      id: "1",
      name: "1",
      items: [
        TextItem("a"),
        TextItem("b"),
        TextItem("c"),
        TextItem("d"),
      ],
    );

    boardData.addColumn(column);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AFBoard(
      dataController: boardData,
      cardBuilder: (context, item) {
        return _RowWidget(item: item as TextItem, key: ObjectKey(item));
      },
    );
  }
}

class _RowWidget extends StatelessWidget {
  final TextItem item;
  const _RowWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(item),
      height: 60,
      color: Colors.green,
      child: Center(child: Text(item.s)),
    );
  }
}

class TextItem extends AFColumnItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}
