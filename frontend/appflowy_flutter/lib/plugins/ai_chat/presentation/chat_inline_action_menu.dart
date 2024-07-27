import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class ChatActionMenuItem {
  String get title;
}

abstract class ChatActionHandler {
  List<ChatActionMenuItem> get items;
  void onEnter();
  void onSelected(ChatActionMenuItem item);
  void onExit();
}

abstract class ChatAnchor {
  GlobalKey get anchorKey;
  LayerLink get layerLink;
}

const int _itemHeight = 34;
const int _itemVerticalPadding = 4;

class ChatActionsMenu {
  ChatActionsMenu({
    required this.anchor,
    required this.context,
    required this.handler,
    required this.style,
  });

  final BuildContext context;
  final ChatAnchor anchor;
  final ChatActionsMenuStyle style;
  final ChatActionHandler handler;

  OverlayEntry? _overlayEntry;

  void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    handler.onExit();
  }

  void show() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    if (_overlayEntry != null) {
      dismiss();
    }

    if (anchor.anchorKey.currentContext == null) {
      return;
    }

    handler.onEnter();

    final height = handler.items.length * (_itemHeight + _itemVerticalPadding);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: anchor.layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, -height - 4),
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 200,
                  maxHeight: 200,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: ActionList(
                    handler: handler,
                    onDismiss: () => dismiss(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.item,
    required this.onTap,
    required this.isSelected,
  });

  final ChatActionMenuItem item;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _itemHeight.toDouble(),
      padding: const EdgeInsets.symmetric(vertical: _itemVerticalPadding / 2.0),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        iconPadding: 10.0,
        text: FlowyText.regular(
          item.title,
        ),
        onTap: onTap,
      ),
    );
  }
}

class ActionList extends StatefulWidget {
  const ActionList({super.key, required this.handler, required this.onDismiss});

  final ChatActionHandler handler;
  final VoidCallback? onDismiss;

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
  final FocusScopeNode _focusNode =
      FocusScopeNode(debugLabel: 'ChatActionsMenu');
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(event) {
    setState(() {
      if (event is KeyDownEvent || event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _selectedIndex = (_selectedIndex + 1) % widget.handler.items.length;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _selectedIndex = (_selectedIndex - 1 + widget.handler.items.length) %
              widget.handler.items.length;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          widget.handler.onSelected(widget.handler.items[_selectedIndex]);
          widget.onDismiss?.call();
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss?.call();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusNode,
      onKey: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.handled;
      },
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: widget.handler.items.asMap().entries.map((entry) {
          final index = entry.key;
          final ChatActionMenuItem item = entry.value;
          return _ActionItem(
            item: item,
            onTap: () {
              widget.handler.onSelected(item);
              widget.onDismiss?.call();
            },
            isSelected: _selectedIndex == index,
          );
        }).toList(),
      ),
    );
  }
}

class ChatActionsMenuStyle {
  ChatActionsMenuStyle({
    required this.backgroundColor,
    required this.groupTextColor,
    required this.menuItemTextColor,
    required this.menuItemSelectedColor,
    required this.menuItemSelectedTextColor,
  });

  const ChatActionsMenuStyle.light()
      : backgroundColor = Colors.white,
        groupTextColor = const Color(0xFF555555),
        menuItemTextColor = const Color(0xFF333333),
        menuItemSelectedColor = const Color(0xFFE0F8FF),
        menuItemSelectedTextColor = const Color.fromARGB(255, 56, 91, 247);

  const ChatActionsMenuStyle.dark()
      : backgroundColor = const Color(0xFF282E3A),
        groupTextColor = const Color(0xFFBBC3CD),
        menuItemTextColor = const Color(0xFFBBC3CD),
        menuItemSelectedColor = const Color(0xFF00BCF0),
        menuItemSelectedTextColor = const Color(0xFF131720);

  final Color backgroundColor;
  final Color groupTextColor;
  final Color menuItemTextColor;
  final Color menuItemSelectedColor;
  final Color menuItemSelectedTextColor;
}
