import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/emoji_picker/emoji_menu_item.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/l10n.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/color_picker.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

const String kCalloutType = 'callout';
const String kCalloutAttrColor = 'color';
const String kCalloutAttrEmoji = 'emoji';

SelectionMenuItem calloutMenuItem = SelectionMenuItem.node(
  name: 'Callout',
  iconData: Icons.note,
  keywords: ['callout'],
  nodeBuilder: (editorState) {
    final node = Node(type: kCalloutType);
    node.insert(TextNode.empty());
    return node;
  },
  replace: (_, textNode) => textNode.toPlainText().isEmpty,
  updateSelection: (_, path, __, ___) {
    return Selection.single(path: [...path, 0], startOffset: 0);
  },
);

class CalloutNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _CalloutWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) => node.type == kCalloutType;
}

class _CalloutWidget extends StatefulWidget {
  const _CalloutWidget({
    super.key,
    required this.node,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<_CalloutWidget> createState() => _CalloutWidgetState();
}

class _CalloutWidgetState extends State<_CalloutWidget> with SelectableMixin {
  bool isHover = false;
  final PopoverController colorPopoverController = PopoverController();
  final PopoverController emojiPopoverController = PopoverController();
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  void initState() {
    widget.node.addListener(nodeChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.node.removeListener(nodeChanged);
    super.dispose();
  }

  void nodeChanged() {
    if (widget.node.children.isEmpty) {
      unlink();
    }
  }

  void unlink() {
    final transaction = widget.editorState.transaction..deleteNode(widget.node);
    widget.editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHover = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHover = false;
        });
      },
      child: Stack(
        children: [
          _buildCallout(),
          Positioned(top: 5, right: 5, child: _buildMenu()),
        ],
      ),
    );
  }

  Widget _buildCallout() {
    final themeExtension = Theme.of(context).extension<AFThemeExtension>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: color ?? themeExtension?.tint1,
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 0, right: 15),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmoji(),
          Expanded(
            child: EditorNodeWidget(
              node: widget.node,
              editorState: widget.editorState,
            ),
          ),
        ],
      ),
    );
  }

  Widget _popover({
    required PopoverController controller,
    required Widget Function(BuildContext context) popupBuilder,
    required Widget child,
    Size size = const Size(200, 460),
  }) {
    return AppFlowyPopover(
        controller: controller,
        constraints: BoxConstraints.loose(size),
        triggerActions: 0,
        popupBuilder: popupBuilder,
        child: child);
  }

  Widget _buildMenu() {
    return _popover(
      controller: colorPopoverController,
      popupBuilder: (context) => _buildColorPicker(),
      child: isHover
          ? Wrap(
              children: [
                FlowyIconButton(
                  icon: const Icon(Icons.color_lens_outlined),
                  onPressed: () {
                    colorPopoverController.show();
                  },
                ),
                FlowyIconButton(
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () {
                    deleteNode();
                  },
                )
              ],
            )
          : const SizedBox(width: 0),
    );
  }

  Widget _buildColorPicker() {
    return FlowyColorPicker(
      colors: FlowyTint.values
          .map((t) => ColorOption(
                color: t.color(context),
                name: t.tintName(FlowyInfraLocalizations.current),
              ))
          .toList(),
      selected: color,
      onTap: (color, index) {
        setColor(color);
        colorPopoverController.close();
      },
    );
  }

  Widget _buildEmoji() {
    return _popover(
      controller: emojiPopoverController,
      popupBuilder: (context) => _buildEmojiPicker(),
      size: const Size(300, 200),
      child: FlowyTextButton(
        emoji,
        fontSize: 18,
        fillColor: Colors.transparent,
        onPressed: () {
          emojiPopoverController.show();
        },
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiSelectionMenu(
      editorState: widget.editorState,
      onSubmitted: (emoji) {
        setEmoji(emoji.emoji);
        emojiPopoverController.close();
      },
      onExit: () {},
    );
  }

  void setColor(Color color) {
    final transaction = widget.editorState.transaction
      ..updateNode(widget.node, {
        kCalloutAttrColor: color.value,
      });
    widget.editorState.apply(transaction);
  }

  void setEmoji(String emoji) {
    final transaction = widget.editorState.transaction
      ..updateNode(widget.node, {
        kCalloutAttrEmoji: emoji,
      });
    widget.editorState.apply(transaction);
  }

  void deleteNode() {
    final transaction = widget.editorState.transaction..deleteNode(widget.node);
    widget.editorState.apply(transaction);
  }

  Color? get color {
    final int? colorValue = widget.node.attributes[kCalloutAttrColor];
    return colorValue != null ? Color(colorValue) : null;
  }

  String get emoji {
    return widget.node.attributes[kCalloutAttrEmoji] ?? "💡";
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.borderLine;

  @override
  Rect? getCursorRectInPosition(Position position) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) =>
      [Offset.zero & _renderBox.size];

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);
}
