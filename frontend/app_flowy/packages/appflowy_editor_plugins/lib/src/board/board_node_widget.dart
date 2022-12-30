// import 'package:appflowy_editor/appflowy_editor.dart';
// import 'package:appflowy_editor_plugins/src/board/mutil_board.dart';
// import 'package:flutter/material.dart';

// const String kBoardType = 'board';

// class BoardWidgetBuilder extends NodeWidgetBuilder<Node> {
//   @override
//   Widget build(NodeWidgetContext<Node> context) {
//     return _BoardWidget(
//       key: context.node.key,
//       node: context.node,
//       editorState: context.editorState,
//     );
//   }

//   @override
//   NodeValidator<Node> get nodeValidator => (node) {
//         return true;
//       };
// }

// class _BoardWidget extends StatefulWidget {
//   const _BoardWidget({
//     Key? key,
//     required this.node,
//     required this.editorState,
//   }) : super(key: key);

//   final Node node;
//   final EditorState editorState;

//   @override
//   State<_BoardWidget> createState() => _BoardWidgetState();
// }

// class _BoardWidgetState extends State<_BoardWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (event) {
//         widget.editorState.service.scrollService?.disable();
//       },
//       onExit: (event) {
//         widget.editorState.service.scrollService?.enable();
//       },
//       child: const SizedBox(
//         height: 400,
//         child: MultiBoardListExample(),
//       ),
//     );

//     // SizedBox(
//     //   height: 200,
//     //   child: SingleChildScrollView(
//     //     child: Column(
//     //       children: [
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //         Text('abcdsssssssssssssssssssssssssssssssssssss'),
//     //       ],
//     //     ),
//     //   ),
//     // );
//   }
// }
