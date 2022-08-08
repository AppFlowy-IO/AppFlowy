# appflowy_board

The **appflowy_board** is a package that is used in [AppFlowy](https://github.com/AppFlowy-IO/AppFlowy). For the moment, this package is iterated very fast.


**appflowy_board** will be a standard git repository when it becomes stable.
## Getting Started


```dart
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

    boardDataController.addColumn(column1);
    boardDataController.addColumn(column2);
    boardDataController.addColumn(column3);

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
```