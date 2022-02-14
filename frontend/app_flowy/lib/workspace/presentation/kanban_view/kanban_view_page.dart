import 'package:boardview/board_item.dart';
import 'package:boardview/board_list.dart';
import 'package:boardview/boardview_controller.dart';
import 'package:flutter/material.dart';
import 'package:boardview/boardview.dart' hide OnDropList, OnDropItem;

import './models.dart';

class KanbanPage extends StatelessWidget {
  const KanbanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: 32, left: 16, right: 16),
        child: KanbanView(),
      ),
    );
  }
}

class KanbanView extends StatefulWidget {
  const KanbanView({Key? key}) : super(key: key);

  @override
  _KanbanViewState createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
// class KanbanView extends StatelessWidget {
  // KanbanView({Key? key}) : super(key: key);

  final List<BoardColumn> _boardColumns = _defaultBoardColumns;

  //Can be used to animate to different sections of the BoardView
  final _boardViewController = BoardViewController();
  final _columnController = TextEditingController();
  final _cardController = TextEditingController();

  @override
  void dispose() {
    _columnController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BoardList> _lists = [];
    for (int i = 0; i < _boardColumns.length; i++) {
      _lists.add(_boardList(context, _boardColumns[i], i));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kanban', style: Theme.of(context).textTheme.headline6),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _boardColumns.add(BoardColumn(title: '', newColumn: true));
                });
              },
              child: Text('Add Column'),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: BoardView(
            boardViewController: _boardViewController,
            scrollbar: true,
            lists: _lists,
          ),
        ),
      ],
    );
  }

  BoardList _boardList(BuildContext context, BoardColumn column, int columnIndex) {
    if (column.newColumn) {
      return BoardList(
        margin: const EdgeInsets.only(right: 32),
        header: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: TextField(
              onSubmitted: (value) {
                setState(() {
                  _boardColumns[columnIndex] = BoardColumn(title: value, newColumn: false);
                });
              },
              controller: _columnController,
              autofocus: true,
              scrollPadding: EdgeInsets.zero,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                isDense: true,
                hintText: 'Type a name...',
              ),
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
              // cursorColor: widget.cursorColor,
              // obscureText: widget.enableObscure,
            ),
          ),
        ),
      );
    }

    List<BoardItem> items = [];
    for (int i = 0; i < column.cards.length; i++) {
      items.insert(i, _boardItem(column.cards[i], columnIndex, i));
    }

    return BoardList(
      onStartDragList: (int? index) {},
      onTapList: (int? index) async {},
      onDropList: (int? index, int? oldIndex) {
        //Update our local list data
        var list = _boardColumns[oldIndex!];
        _boardColumns.removeAt(oldIndex);
        _boardColumns.insert(index!, list);
      },
      margin: const EdgeInsets.only(right: 32),
      header: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              column.title,
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: column.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            _CardCount(count: column.cards.length, color: column.color),
            const Spacer(),
            IconButton(
                padding: EdgeInsets.symmetric(horizontal: 4),
                hoverColor: Colors.transparent,
                constraints: BoxConstraints(),
                // splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {},
                icon: Icon(Icons.more_horiz_rounded),
                iconSize: 16),
            const SizedBox(width: 4),
            IconButton(
                padding: EdgeInsets.symmetric(horizontal: 4),
                hoverColor: Colors.transparent,
                // splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                constraints: BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _boardColumns[columnIndex].cards.insert(0, BoardCard(title: '', newCard: true));
                  });
                },
                icon: Icon(Icons.add),
                iconSize: 16),
          ],
        ),
      ),
      items: items,
    );
  }

  BoardItem _boardItem(BoardCard card, int columnIndex, int cardIndex) {
    if (card.newCard) {
      // setState(() {
      //   _boardColumns[columnIndex].cards[cardIndex].copyWith(newCard: false);
      // });

      return BoardItem(
        item: Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: TextField(
              onSubmitted: (value) {
                setState(() {
                  _boardColumns[columnIndex].cards[cardIndex] = BoardCard(title: value, newCard: false);
                });
              },
              controller: _cardController,
              autofocus: true,
              scrollPadding: EdgeInsets.zero,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                isDense: true,
                hintText: 'Type a name...',
              ),
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    // color: theme.textColor,
                    // fontSize: 14,
                    // fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                  ),
              // cursorColor: widget.cursorColor,
              // obscureText: widget.enableObscure,
            ),
          ),
        ),
      );
    }

    return BoardItem(
      onStartDragItem: (int? listIndex, int? itemIndex, BoardItemState? state) {},
      onDropItem: (int? listIndex, int? itemIndex, int? oldListIndex, int? oldItemIndex, BoardItemState? state) {
        //Used to update our local item data
        // FIXME: Bug when dragging.
        var item = _boardColumns[oldListIndex!].cards[oldItemIndex!];
        _boardColumns[oldListIndex].cards.removeAt(oldItemIndex);
        _boardColumns[listIndex!].cards.insert(itemIndex!, item);
      },
      onTapItem: (int? listIndex, int? itemIndex, BoardItemState? state) async {},
      item: Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(card.title),
        ),
      ),
    );
  }
}

// class _BoardColumn extends StatefulWidget {
//   const _BoardColumn({
//     Key? key,
//     required this.column,
//     this.onDropList,
//     this.onDropItem,
//   }) : super(key: key);

//   final BoardColumn column;
//   final OnDropList? onDropList;
//   final OnDropItem? onDropItem;

//   @override
//   __BoardColumnState createState() => __BoardColumnState();
// }

// class __BoardColumnState extends State<_BoardColumn> {
//   bool _isIconsHidden = true;

//   @override
//   Widget build(BuildContext context) {
//     // return BoardList _boardList(BuildContext context, BoardColumn column) {
//     List<BoardItem> items = [];
//     for (int i = 0; i < widget.column.cards.length; i++) {
//       items.insert(i, _boardItem(widget.column.cards[i]) as BoardItem);
//     }

//     return BoardList(
//       onStartDragList: (int? index) {},
//       onTapList: (int? index) async {},
//       onDropList: widget.onDropList,
//       // onDropList: (int? index, int? oldIndex) {
//       //   //Update our local list data
//       //   var list = _boardColumns[oldIndex!];
//       //   _boardColumns.removeAt(oldIndex);
//       //   _boardColumns.insert(index!, list);
//       // },
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       header: MouseRegion(
//         onEnter: (_) => setState(() => _isIconsHidden = false),
//         onExit: (_) => setState(() => _isIconsHidden = true),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           child: Row(
//             // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 widget.column.title,
//                 style: Theme.of(context).textTheme.bodyText1!.copyWith(
//                       fontWeight: FontWeight.w700,
//                     ),
//               ),
//               const SizedBox(width: 4),
//               _CardCount(count: widget.column.cards.length, color: Colors.grey),
//               const Spacer(),
//               Visibility(
//                 maintainSize: true,
//                 maintainAnimation: true,
//                 maintainState: true,
//                 visible: _isIconsHidden,
//                 child: Row(
//                   children: [
//                     IconButton(
//                         padding: EdgeInsets.symmetric(horizontal: 4),
//                         hoverColor: Colors.transparent,
//                         constraints: BoxConstraints(),
//                         // splashColor: Colors.transparent,
//                         highlightColor: Colors.transparent,
//                         onPressed: () {},
//                         icon: Icon(Icons.more_horiz_rounded),
//                         iconSize: 16),
//                     const SizedBox(width: 4),
//                     IconButton(
//                         padding: EdgeInsets.symmetric(horizontal: 4),
//                         hoverColor: Colors.transparent,
//                         // splashColor: Colors.transparent,
//                         highlightColor: Colors.transparent,
//                         constraints: BoxConstraints(),
//                         onPressed: () {},
//                         icon: Icon(Icons.add),
//                         iconSize: 16),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       items: items,
//     );
//   }

//   Widget _boardItem(BoardCard card) {
//     return BoardItem(
//       onStartDragItem: (int? listIndex, int? itemIndex, BoardItemState? state) {},
//       onDropItem: widget.onDropItem,
//       // onDropItem: (int? listIndex, int? itemIndex, int? oldListIndex, int? oldItemIndex,
//       //     BoardItemState? state) {
//       //   //Used to update our local item data
//       //   // FIXME: Bug when dragging.
//       //   var item = _boardColumns[oldListIndex!].cards[oldItemIndex!];
//       //   _boardColumns[oldListIndex].cards.removeAt(oldItemIndex);
//       //   _boardColumns[listIndex!].cards.insert(itemIndex!, item);
//       // },
//       onTapItem: (int? listIndex, int? itemIndex, BoardItemState? state) async {},
//       item: Card(
//         margin: EdgeInsets.symmetric(vertical: 4),
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(card.title),
//         ),
//       ),
//     );
//   }
// }

class _CardCount extends StatelessWidget {
  const _CardCount({Key? key, required this.count, required this.color}) : super(key: key);

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.bodyText2!.copyWith(
              fontSize: 12,
              color: Colors.grey.shade300,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

final _defaultBoardColumns = [
  BoardColumn(title: '✋🏻 Open', colorHex: Colors.blue.value, cards: [
    BoardCard(title: 'Grid View'),
    BoardCard(title: 'Board View'),
    BoardCard(title: 'iOS App'),
    BoardCard(title: 'Android App'),
    BoardCard(title: 'Sync'),
  ]),
  BoardColumn(title: '🚧  In Progress', colorHex: Colors.yellow.value, cards: [
    BoardCard(title: 'Emoji Picker'),
    BoardCard(title: 'Drag and Move Block'),
  ]),
  BoardColumn(title: '📛  Blocked', colorHex: Colors.red.value, cards: [
    BoardCard(title: 'Formatting Toolbar'),
  ]),
  BoardColumn(title: '✅  Complete', colorHex: Colors.green.value, cards: [
    BoardCard(title: 'Dark Mode'),
  ]),
  BoardColumn(title: '🚀  Releases', colorHex: Colors.purple.value, cards: [
    BoardCard(title: 'Windows App'),
    BoardCard(title: 'Linux App'),
    BoardCard(title: 'MacOS App'),
  ]),
];
