import 'package:flowy_board/flowy_board.dart';
import 'package:flutter/material.dart';

class MultiBoardListExample extends StatefulWidget {
  const MultiBoardListExample({Key? key}) : super(key: key);

  @override
  State<MultiBoardListExample> createState() => _MultiBoardListExampleState();
}

class _MultiBoardListExampleState extends State<MultiBoardListExample> {
  final BoardDataController boardDataController = BoardDataController();

  @override
  void initState() {
    final column1 = BoardColumnData(id: "1", items: [
      TextItem("a"),
      TextItem("b"),
      TextItem("c"),
      TextItem("d"),
    ]);
    final column2 = BoardColumnData(id: "2", items: [
      TextItem("1"),
      TextItem("2"),
      TextItem("3"),
      TextItem("4"),
      TextItem("5"),
    ]);

    final column3 = BoardColumnData(id: "3", items: [
      TextItem("A"),
      TextItem("B"),
      TextItem("C"),
      TextItem("D"),
    ]);

    boardDataController.setColumnData(column1);
    boardDataController.setColumnData(column2);
    boardDataController.setColumnData(column3);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Board(
      dataController: boardDataController,
      background: Container(color: Colors.red),
      footBuilder: (context, columnData) {
        return Container(
          color: Colors.purple,
          height: 30,
        );
      },
      headerBuilder: (context, columnData) {
        return Container(
          color: Colors.yellow,
          height: 30,
        );
      },
      cardBuilder: (context, item) {
        return _RowWidget(item: item as TextItem, key: ObjectKey(item));
      },
      columnConstraints: const BoxConstraints.tightFor(width: 240),
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

class TextItem extends ColumnItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}
