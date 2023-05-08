// import 'package:appflowy/plugins/document/presentation/plugins/plugins.dart';
// import 'package:appflowy_editor/appflowy_editor.dart';
// import 'package:appflowy_popover/appflowy_popover.dart';
// import 'package:flowy_infra/theme_extension.dart';
// import 'package:flowy_infra_ui/flowy_infra_ui.dart';
// import 'package:flutter/material.dart';

// class CalloutBlockKeys {
//   const CalloutBlockKeys._();

//   /// The background color of a callout block.
//   ///
//   /// The value is a String.
//   static const String color = 'color';

//   /// The emoji of a callout block.
//   ///
//   /// The value is a String.
//   static const String emoji = 'emoji';
// }

// Node calloutNode({
//   String emoji = '📌',
//   Attributes? attributes,
// }) {
//   attributes ??= {
//     'delta': Delta().toJson(),
//     'emoji': emoji,
//   };
//   return Node(
//     type: 'callout',
//     attributes: attributes,
//   );
// }

// SelectionMenuItem calloutItem = SelectionMenuItem.node(
//   name: 'Callout',
//   iconData: Icons.note,
//   keywords: ['callout'],
//   nodeBuilder: (editorState) => calloutNode(),
//   replace: (_, node) => node.delta?.isEmpty ?? false,
//   updateSelection: (_, path, __, ___) {
//     return Selection.single(path: [...path, 0], startOffset: 0);
//   },
// );

// class CalloutBlockComponentBuilder extends BlockComponentBuilder {
//   const CalloutBlockComponentBuilder({
//     this.configuration = const BlockComponentConfiguration(),
//   });

//   final BlockComponentConfiguration configuration;

//   @override
//   Widget build(BlockComponentContext blockComponentContext) {
//     final node = blockComponentContext.node;
//     return CalloutBlockComponentWidget(
//       key: node.key,
//       node: node,
//       configuration: configuration,
//     );
//   }

//   @override
//   bool validate(Node node) =>
//       node.delta != null &&
//       node.children.isEmpty &&
//       node.attributes[CalloutBlockKeys.emoji] is String;
// }

// class CalloutBlockComponentWidget extends StatefulWidget {
//   const CalloutBlockComponentWidget({
//     super.key,
//     required this.node,
//     required this.configuration,
//   });

//   final Node node;
//   final BlockComponentConfiguration configuration;

//   @override
//   State<CalloutBlockComponentWidget> createState() =>
//       _CalloutBlockComponentWidgetState();
// }

// class _CalloutBlockComponentWidgetState
//     extends State<CalloutBlockComponentWidget>
//     with SelectableMixin, DefaultSelectable, BlockComponentConfigurable {
//   @override
//   final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

//   @override
//   GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

//   @override
//   BlockComponentConfiguration get configuration => widget.configuration;

//   @override
//   Node get node => widget.node;

//   final PopoverController colorPopoverController = PopoverController();
//   final PopoverController emojiPopoverController = PopoverController();
//   RenderBox get _renderBox => context.findRenderObject() as RenderBox;

//   @override
//   void initState() {
//     widget.node.addListener(nodeChanged);
//     super.initState();
//   }

//   @override
//   void dispose() {
//     widget.node.removeListener(nodeChanged);
//     super.dispose();
//   }

//   void nodeChanged() {
//     if (widget.node.children.isEmpty) {
//       deleteNode();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(8.0)),
//         color: tint.color(context),
//       ),
//       padding: const EdgeInsets.only(top: 8, bottom: 8, left: 0, right: 15),
//       width: double.infinity,
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildEmoji(),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: widget.node.children
//                   .map(
//                     (child) => widget.editorState.service.renderPluginService
//                         .buildPluginWidget(
//                       child is TextNode
//                           ? NodeWidgetContext<TextNode>(
//                               context: context,
//                               node: child,
//                               editorState: widget.editorState,
//                             )
//                           : NodeWidgetContext<Node>(
//                               context: context,
//                               node: child,
//                               editorState: widget.editorState,
//                             ),
//                     ),
//                   )
//                   .toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _popover({
//     required PopoverController controller,
//     required Widget Function(BuildContext context) popupBuilder,
//     required Widget child,
//     Size size = const Size(200, 460),
//   }) {
//     return AppFlowyPopover(
//       controller: controller,
//       constraints: BoxConstraints.loose(size),
//       triggerActions: 0,
//       popupBuilder: popupBuilder,
//       child: child,
//     );
//   }

//   Widget _buildColorPicker() {
//     return FlowyColorPicker(
//       colors: FlowyTint.values
//           .map(
//             (t) => ColorOption(
//               color: t.color(context),
//               name: t.tintName(AppFlowyEditorLocalizations.current),
//             ),
//           )
//           .toList(),
//       selected: tint.color(context),
//       onTap: (color, index) {
//         setColor(FlowyTint.values[index]);
//         colorPopoverController.close();
//       },
//     );
//   }

//   Widget _buildEmoji() {
//     return _popover(
//       controller: emojiPopoverController,
//       popupBuilder: (context) => _buildEmojiPicker(),
//       size: const Size(300, 200),
//       child: FlowyTextButton(
//         emoji,
//         fontSize: 18,
//         fillColor: Colors.transparent,
//         onPressed: () {
//           emojiPopoverController.show();
//         },
//       ),
//     );
//   }

//   Widget _buildEmojiPicker() {
//     return EmojiSelectionMenu(
//       editorState: widget.editorState,
//       onSubmitted: (emoji) {
//         setEmoji(emoji.emoji);
//         emojiPopoverController.close();
//       },
//       onExit: () {},
//     );
//   }

//   void setColor(FlowyTint tint) {
//     final transaction = widget.editorState.transaction
//       ..updateNode(widget.node, {
//         kCalloutAttrColor: tint.name,
//       });
//     widget.editorState.apply(transaction);
//   }

//   void setEmoji(String emoji) {
//     final transaction = widget.editorState.transaction
//       ..updateNode(widget.node, {
//         kCalloutAttrEmoji: emoji,
//       });
//     widget.editorState.apply(transaction);
//   }

//   void deleteNode() {
//     final transaction = widget.editorState.transaction..deleteNode(widget.node);
//     widget.editorState.apply(transaction);
//   }

//   FlowyTint get tint {
//     final name = widget.node.attributes[kCalloutAttrColor];
//     return (name is String) ? FlowyTint.fromJson(name) : FlowyTint.tint1;
//   }

//   String get emoji {
//     return widget.node.attributes[kCalloutAttrEmoji] ?? "💡";
//   }

//   @override
//   Position start() => Position(path: widget.node.path, offset: 0);

//   @override
//   Position end() => Position(path: widget.node.path, offset: 1);

//   @override
//   Position getPositionInOffset(Offset start) => end();

//   @override
//   bool get shouldCursorBlink => false;

//   @override
//   CursorStyle get cursorStyle => CursorStyle.borderLine;

//   @override
//   Rect? getCursorRectInPosition(Position position) {
//     final size = _renderBox.size;
//     return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
//   }

//   @override
//   List<Rect> getRectsInSelection(Selection selection) =>
//       [Offset.zero & _renderBox.size];

//   @override
//   Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
//         path: widget.node.path,
//         startOffset: 0,
//         endOffset: 1,
//       );

//   @override
//   Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);
// }
