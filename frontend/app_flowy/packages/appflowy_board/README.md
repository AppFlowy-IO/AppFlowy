# appflowy_board

The **appflowy_board** is a package that is used in [AppFlowy](https://github.com/AppFlowy-IO/AppFlowy). For the moment, this package is iterated very fast.


**appflowy_board** will be a standard git repository when it becomes stable.
## Getting Started

<p>
<img src="https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_board/example/gifs/appflowy_board_video_2.gif?raw=true" width="680" title="AppFlowyBoard">
<img src="https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_board/example/gifs/appflowy_board_video_1.gif?raw=true" width="680" title="AppFlowyBoard">
</p>

```dart
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
```