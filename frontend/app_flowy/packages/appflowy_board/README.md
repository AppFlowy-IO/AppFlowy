# appflowy_board

<h1 align="center"><b>AppFlowy Board</b></h1>

<p align="center">A customizable and draggable Kanban Board widget for Flutter</p>

<p align="center">
    <a href="https://discord.gg/ZCCYN4Anzq"><b>Discord</b></a> •
    <a href="https://twitter.com/appflowy"><b>Twitter</b></a>
</p>


<p align="center">
<img src="https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_board/example/gifs/appflowy_board_video_1.gif?raw=true" width="680" title="AppFlowyBoard">
</p>

## Intro

appflowy_board is a customizable and draggable Kanban Board widget for Flutter. 
You can use it to create a Kanban Board tool like those in Trello. 

Check out [AppFlowy](https://github.com/AppFlowy-IO/AppFlowy) to see how appflowy_board is used to build a BoardView database.
<p align="center">
<img src="https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_board/example/gifs/appflowy_board_video_2.gif?raw=true" width="680" title="AppFlowyBoard">
</p>


## Getting Started
Add the AppFlowy Board [Flutter package](https://docs.flutter.dev/development/packages-and-plugins/using-packages) to your environment.

With Flutter:
```dart
flutter pub add appflowy_board
flutter pub get
```

This will add a line like this to your package's pubspec.yaml:
```dart
dependencies:
  appflowy_board: ^0.0.6
```

## Create your first board

Initialize an `AppFlowyBoardController` for the board. It contains the data used by the board. You can
register callbacks to receive the changes of the board.

```dart

final AppFlowyBoardController controller = AppFlowyBoardController(
  onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
    debugPrint('Move item from $fromIndex to $toIndex');
  },
  onMoveGroupItem: (groupId, fromIndex, toIndex) {
    debugPrint('Move $groupId:$fromIndex to $groupId:$toIndex');
  },
  onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
    debugPrint('Move $fromGroupId:$fromIndex to $toGroupId:$toIndex');
  },
);
```

Provide an initial value of the board by initializing the `AppFlowyGroupData`. It represents a group data and contains list of items. Each item displayed in the group requires to implement the `AppFlowyGroupItem` class.

```dart

void initState() {
  final group1 = AppFlowyGroupData(id: "To Do", items: [
    TextItem("Card 1"),
    TextItem("Card 2"),
  ]);
  final group2 = AppFlowyGroupData(id: "In Progress", items: [
    TextItem("Card 3"),
    TextItem("Card 4"),
  ]);

  final group3 = AppFlowyGroupData(id: "Done", items: []);

  controller.addGroup(group1);
  controller.addGroup(group2);
  controller.addGroup(group3);
  super.initState();
}

class TextItem extends AppFlowyGroupItem {
  final String s;
  TextItem(this.s);

  @override
  String get id => s;
}

```

Finally, return a `AppFlowyBoard` widget in the build method.

```dart

@override
Widget build(BuildContext context) {
  return AppFlowyBoard(
    controller: controller,
    cardBuilder: (context, group, groupItem) {
      final textItem = groupItem as TextItem;
      return AppFlowyGroupCard(
        key: ObjectKey(textItem),
        child: Text(textItem.s),
      );
    },
    groupConstraints: const BoxConstraints.tightFor(width: 240),
  ); 
}

```

## Usage Example
To quickly grasp how it can be used, look at the /example/lib folder.
First, run main.dart to play with the demo.


Second, let's delve into multi_board_list_example.dart to understand a few key components:
* A Board widget is created via instantiating an `AppFlowyBoard` object. 
* In the `AppFlowyBoard` object, you can find the `AppFlowyBoardController`, which is defined in board_data.dart, is feeded with prepopulated mock data. It also contains callback functions to materialize future user data.
* Three builders: AppFlowyBoardHeaderBuilder, AppFlowyBoardFooterBuilder, AppFlowyBoardCardBuilder. See below image for what they are used for.


<p>
<img src="https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_board/example/gifs/appflowy_board_builders.jpg?raw=true" width="200" title="AppFlowyBoard">
</p>

## Glossary
Please refer to the API documentation.

## Contributing
Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

Please look at [CONTRIBUTING.md](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/contributing-to-appflowy) for details.

## License
Distributed under the AGPLv3 License. See [LICENSE](https://github.com/AppFlowy-IO/AppFlowy-Docs/blob/main/LICENSE) for more information.
