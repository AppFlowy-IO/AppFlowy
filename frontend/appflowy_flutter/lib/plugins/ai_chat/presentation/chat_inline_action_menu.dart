import 'dart:math';

import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

abstract class ChatActionMenuItem {
  String get title;
  String get id;
}

abstract class ChatActionHandler {
  void onEnter();
  void onSelected(ChatActionMenuItem item);
  void onExit();
  ChatInputActionBloc get commandBloc;
  void onFilter(String filter);
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
    const double maxHeight = 300;

    _overlayEntry = OverlayEntry(
      builder: (context) => BlocProvider.value(
        value: handler.commandBloc,
        child: BlocBuilder<ChatInputActionBloc, ChatInputActionState>(
          builder: (context, state) {
            final height = min(
              state.items.length * (_itemHeight + _itemVerticalPadding),
              maxHeight,
            );
            return Stack(
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
                        maxHeight: maxHeight,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: ActionList(
                            handler: handler,
                            onDismiss: () => dismiss(),
                            items: state.items,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
  const ActionList({
    super.key,
    required this.handler,
    required this.onDismiss,
    required this.items,
  });

  final ChatActionHandler handler;
  final VoidCallback? onDismiss;
  final List<ChatActionMenuItem> items;

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
  int _selectedIndex = 0;
  final _scrollController = AutoScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(event) {
    bool isHandle = false;
    setState(() {
      // ignore: deprecated_member_use
      if (event is KeyDownEvent || event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _selectedIndex = (_selectedIndex + 1) % widget.items.length;
          _scrollToSelectedIndex();
          isHandle = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _selectedIndex =
              (_selectedIndex - 1 + widget.items.length) % widget.items.length;
          _scrollToSelectedIndex();
          isHandle = true;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          widget.handler.onSelected(widget.items[_selectedIndex]);
          widget.onDismiss?.call();
          isHandle = true;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss?.call();
          isHandle = true;
        }
      }
    });
    return isHandle ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatInputActionBloc, ChatInputActionState>(
      listenWhen: (previous, current) => previous.keyEvent != current.keyEvent,
      listener: (context, state) {
        if (state.keyEvent != null) {
          _handleKeyPress(state.keyEvent!);
        }
      },
      child: ListView(
        shrinkWrap: true,
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        children: widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final ChatActionMenuItem item = entry.value;
          return AutoScrollTag(
            key: ValueKey(item.id),
            index: index,
            controller: _scrollController,
            child: _ActionItem(
              item: item,
              onTap: () {
                widget.handler.onSelected(item);
                widget.onDismiss?.call();
              },
              isSelected: _selectedIndex == index,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _scrollToSelectedIndex() {
    _scrollController.scrollToIndex(
      _selectedIndex,
      duration: const Duration(milliseconds: 200),
      preferPosition: AutoScrollPosition.begin,
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
