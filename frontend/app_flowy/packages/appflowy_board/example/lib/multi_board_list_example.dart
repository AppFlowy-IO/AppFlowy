import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';

class MultiBoardListExample extends StatefulWidget {
  const MultiBoardListExample({Key? key}) : super(key: key);

  @override
  State<MultiBoardListExample> createState() => _MultiBoardListExampleState();
}

class _MultiBoardListExampleState extends State<MultiBoardListExample> {
  final AppFlowyBoardDataController boardDataController =
      AppFlowyBoardDataController(
    onMoveGroup: (fromColumnId, fromIndex, toColumnId, toIndex) {
      // debugPrint('Move column from $fromIndex to $toIndex');
    },
    onMoveGroupItem: (columnId, fromIndex, toIndex) {
      // debugPrint('Move $columnId:$fromIndex to $columnId:$toIndex');
    },
    onMoveGroupItemToGroup: (fromColumnId, fromIndex, toColumnId, toIndex) {
      // debugPrint('Move $fromColumnId:$fromIndex to $toColumnId:$toIndex');
    },
  );

  @override
  void initState() {
    List<AppFlowyGroupItem> a = [
      TextItem("Card 1"),
      TextItem("Card 2"),
      RichTextItem(title: "Card 3", subtitle: 'Aug 1, 2020 4:05 PM'),
      TextItem("Card 4"),
      TextItem("Card 5"),
      TextItem("Card 6"),
      RichTextItem(title: "Card 7", subtitle: 'Aug 1, 2020 4:05 PM'),
      RichTextItem(title: "Card 8", subtitle: 'Aug 1, 2020 4:05 PM'),
      TextItem("Card 9"),
    ];

    final column1 =
        AppFlowyBoardGroupData(id: "To Do", name: "To Do", items: a);
    final column2 = AppFlowyBoardGroupData(
      id: "In Progress",
      name: "In Progress",
      items: <AppFlowyGroupItem>[
        RichTextItem(title: "Card 10", subtitle: 'Aug 1, 2020 4:05 PM'),
        TextItem("Card 11"),
      ],
    );

    final column3 = AppFlowyBoardGroupData(
        id: "Done", name: "Done", items: <AppFlowyGroupItem>[]);

    boardDataController.addGroup(column1);
    boardDataController.addGroup(column2);
    boardDataController.addGroup(column3);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final config = AppFlowyBoardConfig(
      groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
    );
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: AppFlowyBoard(
          dataController: boardDataController,
          footerBuilder: (context, columnData) {
            return AppFlowyGroupFooter(
              icon: const Icon(Icons.add, size: 20),
              title: const Text('New'),
              height: 50,
              margin: config.groupItemPadding,
            );
          },
          headerBuilder: (context, columnData) {
            return AppFlowyGroupHeader(
              icon: const Icon(Icons.lightbulb_circle),
              title: SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController()
                    ..text = columnData.headerData.groupName,
                  onSubmitted: (val) {
                    boardDataController
                        .getGroupController(columnData.headerData.groupId)!
                        .updateGroupName(val);
                  },
                ),
              ),
              addIcon: const Icon(Icons.add, size: 20),
              moreIcon: const Icon(Icons.more_horiz, size: 20),
              height: 50,
              margin: config.groupItemPadding,
            );
          },
          cardBuilder: (context, column, columnItem) {
            return AppFlowyGroupItemCard(
              key: ValueKey(columnItem.id),
              child: _buildCard(columnItem),
            );
          },
          groupConstraints: const BoxConstraints.tightFor(width: 240),
          config: AppFlowyBoardConfig(
            groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AppFlowyGroupItem item) {
    if (item is TextItem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Text(item.s),
        ),
      );
    }

    if (item is RichTextItem) {
      return RichTextCard(item: item);
    }

    throw UnimplementedError();
  }
}

class RichTextCard extends StatefulWidget {
  final RichTextItem item;
  const RichTextCard({
    required this.item,
    Key? key,
  }) : super(key: key);

  @override
  State<RichTextCard> createState() => _RichTextCardState();
}

class _RichTextCardState extends State<RichTextCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Text(
              widget.item.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}

class TextItem extends AppFlowyGroupItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}

class RichTextItem extends AppFlowyGroupItem {
  final String title;
  final String subtitle;

  RichTextItem({required this.title, required this.subtitle});

  @override
  String get id => title;
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
