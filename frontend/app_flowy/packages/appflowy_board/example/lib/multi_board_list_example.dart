import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';

class MultiBoardListExample extends StatefulWidget {
  const MultiBoardListExample({Key? key}) : super(key: key);

  @override
  State<MultiBoardListExample> createState() => _MultiBoardListExampleState();
}

class _MultiBoardListExampleState extends State<MultiBoardListExample> {
  final BoardDataController boardDataController = BoardDataController(
    onMoveColumn: (fromIndex, toIndex) {
      debugPrint('Move column from $fromIndex to $toIndex');
    },
    onMoveColumnItem: (columnId, fromIndex, toIndex) {
      debugPrint('Move $columnId:$fromIndex to $columnId:$toIndex');
    },
    onMoveColumnItemToColumn: (fromColumnId, fromIndex, toColumnId, toIndex) {
      debugPrint('Move $fromColumnId:$fromIndex to $toColumnId:$toIndex');
    },
  );

  @override
  void initState() {
    final column1 = BoardColumnData(id: "To Do", items: [
      TextItem("Card 1"),
      TextItem("Card 2"),
      TextItem("Card 3"),
      TextItem("Card 4"),
    ]);
    final column2 = BoardColumnData(id: "In Progress", items: [
      TextItem("Card 5"),
      TextItem("Card 6"),
    ]);

    final column3 = BoardColumnData(id: "Done", items: []);

    boardDataController.addColumn(column1);
    boardDataController.addColumn(column2);
    boardDataController.addColumn(column3);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final config = BoardConfig(
      columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
    );
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Board(
          dataController: boardDataController,
          footBuilder: (context, columnData) {
            return AppFlowyColumnFooter(
              icon: const Icon(Icons.add, size: 20),
              title: const Text('New'),
              height: 50,
              margin: config.columnItemPadding,
            );
          },
          headerBuilder: (context, columnData) {
            return AppFlowyColumnHeader(
              icon: const Icon(Icons.lightbulb_circle),
              title: Text(columnData.id),
              addIcon: const Icon(Icons.add, size: 20),
              moreIcon: const Icon(Icons.more_horiz, size: 20),
              height: 50,
              margin: config.columnItemPadding,
            );
          },
          cardBuilder: (context, item) {
            final textItem = item as TextItem;
            return AppFlowyColumnItemCard(
              key: ObjectKey(item),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(textItem.s),
                ),
              ),
            );
          },
          columnConstraints: const BoxConstraints.tightFor(width: 240),
          config: BoardConfig(
            columnBackgroundColor: HexColor.fromHex('#F7F8FC'),
          ),
        ),
      ),
    );
  }
}

class TextItem extends ColumnItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
