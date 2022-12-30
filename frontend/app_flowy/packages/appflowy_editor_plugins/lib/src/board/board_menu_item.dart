// import 'package:appflowy_editor/appflowy_editor.dart';
// import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
// import 'package:flutter/material.dart';

// SelectionMenuItem boardMenuItem = SelectionMenuItem(
//   name: () => 'Board',
//   icon: (editorState, onSelected) => Icon(
//     Icons.emoji_emotions_outlined,
//     color: onSelected
//         ? editorState.editorStyle.selectionMenuItemSelectedIconColor
//         : editorState.editorStyle.selectionMenuItemIconColor,
//     size: 18.0,
//   ),
//   keywords: ['board'],
//   handler: (editorState, _, __) {
//     final selection =
//         editorState.service.selectionService.currentSelection.value;
//     final textNodes = editorState.service.selectionService.currentSelectedNodes
//         .whereType<TextNode>();
//     if (selection == null || textNodes.isEmpty) {
//       return;
//     }
//     final transaction = editorState.transaction;
//     transaction.insertNode(
//       selection.end.path,
//       Node(
//         type: kBoardType,
//       ),
//     );
//     transaction.afterSelection = selection;
//     editorState.apply(transaction);
//   },
// );
