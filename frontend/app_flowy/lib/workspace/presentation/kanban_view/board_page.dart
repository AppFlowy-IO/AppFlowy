// import 'package:boardview/board_item.dart';
// import 'package:boardview/board_list.dart';
// import 'package:boardview/boardview_controller.dart';
// import 'package:flutter/material.dart';

// import 'package:boardview/boardview.dart';

// class BoardListObject {
//   final String title;
//   List<BoardItemObject>? items = [];

//   BoardListObject({this.items, required this.title});
// }

// class BoardItemObject {
//   final String title;
//   final String from;

//   const BoardItemObject({this.title = "", this.from = ""});
// }

// class BoardPage extends StatefulWidget {
//   BoardPage({Key? key}) : super(key: key);

//   @override
//   _BoardPageState createState() => _BoardPageState();
// }

// class _BoardPageState extends State<BoardPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xffffffff),
//         elevation: 0,
//         title: Row(
//           children: <Widget>[
//             Icon(
//               Icons.view_column,
//               color: Color(0xff2F334B),
//             ),
//             SizedBox(
//               width: 20,
//             ),
//             Text(
//               'Pedidos',
//               style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff2F334B)),
//             ),
//           ],
//         ),
//         bottom: PreferredSize(
//             child: Container(
//               color: Colors.grey[300],
//               height: 1.0,
//             ),
//             preferredSize: Size.fromHeight(1.0)),
//       ),
//       body: BoardViewExample(),
//     );
//   }
// }

// class BoardViewExample extends StatelessWidget {
//   final List<BoardListObject> _listData = [
//     BoardListObject(title: "Pedidos nuevos", items: [
//       BoardItemObject(title: '27 Pares de Zapatos Modelo SDF-234d', from: 'Ruben'),
//       BoardItemObject(title: '7 Pares de Bota Modelo SDF-234d', from: 'Martha')
//     ]),
//     BoardListObject(title: "En Proceso"),
//     BoardListObject(title: "Enviados"),
//     BoardListObject(title: "Cancelados"),
//   ];

//   //Can be used to animate to different sections of the BoardView
//   final BoardViewController boardViewController = BoardViewController();

//   @override
//   Widget build(BuildContext context) {
//     List<BoardList> _lists = <BoardList>[];

//     for (int i = 0; i < _listData.length; i++) {
//       _lists.add(_createBoardList(_listData[i]));
//     }

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: BoardView(
//         lists: _lists,
//         boardViewController: boardViewController,
//       ),
//     );
//   }

//   BoardItem buildBoardItem(BoardItemObject itemObject) {
//     return BoardItem(
//         onStartDragItem: (int? listIndex, int? itemIndex, BoardItemState state) {},
//         onDropItem: (int? listIndex, int? itemIndex, int? oldListIndex, int? oldItemIndex, BoardItemState state) {
//           //Used to update our local item data
//           var item = _listData[oldListIndex!].items![oldItemIndex!];

//           _listData[oldListIndex].items!.removeAt(oldItemIndex);

//           _listData[listIndex!].items!.insert(itemIndex!, item);
//         },
//         onTapItem: (int? listIndex, int? itemIndex, BoardItemState state) async {},
//         item: Container(
//           margin: EdgeInsets.fromLTRB(8, 0, 8, 8),
//           child: Card(
//             elevation: 0,
//             child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Text(
//                       itemObject.from,
//                       style:
//                           TextStyle(height: 1.5, color: Color(0xff2F334B), fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(
//                       height: 10.0,
//                     ),
//                     Text(
//                       itemObject.title,
//                       style: TextStyle(height: 1.5, color: Color(0xff2F334B), fontSize: 16),
//                     ),
//                   ],
//                 )),
//           ),
//         ));
//   }

//   BoardList _createBoardList(BoardListObject list) {
//     List<BoardItem> items = [];
//     for (int i = 0; i < list.items!.length; i++) {
//       items.insert(i, buildBoardItem(list.items![i]));
//     }

//     return BoardList(
//       onStartDragList: (int? listIndex) {},
//       onTapList: (int? listIndex) async {},
//       onDropList: (int? listIndex, int? oldListIndex) {
//         //Update our local list data
//         var list = _listData[oldListIndex!];
//         _listData.removeAt(oldListIndex);
//         _listData.insert(listIndex!, list);
//       },
//       headerBackgroundColor: Colors.transparent,
//       backgroundColor: Color(0xffECEDFC),
//       header: [
//         Expanded(
//             child: Container(
//                 padding: EdgeInsets.all(10),
//                 child: Text(
//                   list.title,
//                   style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xff2F334B)),
//                 ))),
//       ],
//       items: items,
//     );
//   }
// }
