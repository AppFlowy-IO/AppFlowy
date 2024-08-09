import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

abstract class ChatActionHandler {
  void onEnter();
  void onSelected(ChatInputMention page);
  void onExit();
  ChatInputActionBloc get commandBloc;
  void onFilter(String filter);
  double actionMenuOffsetX();
}

abstract class ChatAnchor {
  GlobalKey get anchorKey;
  LayerLink get layerLink;
}

const int _itemHeight = 34;
const int _itemVerticalPadding = 4;
const int _noPageHeight = 20;

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
              max(
                state.pages.length * (_itemHeight + _itemVerticalPadding),
                _noPageHeight,
              ),
              maxHeight,
            );
            final isLoading =
                state.indicator == const ChatActionMenuIndicator.loading();

            return Stack(
              children: [
                CompositedTransformFollower(
                  link: anchor.layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(handler.actionMenuOffsetX(), -height - 4),
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
                            vertical: 2,
                          ),
                          child: ActionList(
                            isLoading: isLoading,
                            handler: handler,
                            onDismiss: () => dismiss(),
                            pages: state.pages,
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

  final ChatInputMention item;
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
        leftIcon: item.icon,
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
    required this.pages,
    required this.isLoading,
  });

  final ChatActionHandler handler;
  final VoidCallback? onDismiss;
  final List<ChatInputMention> pages;
  final bool isLoading;

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

  KeyEventResult _handleKeyPress(logicalKey) {
    bool isHandle = false;
    setState(() {
      if (logicalKey == PhysicalKeyboardKey.arrowDown) {
        _selectedIndex = (_selectedIndex + 1) % widget.pages.length;
        _scrollToSelectedIndex();
        isHandle = true;
      } else if (logicalKey == PhysicalKeyboardKey.arrowUp) {
        _selectedIndex =
            (_selectedIndex - 1 + widget.pages.length) % widget.pages.length;
        _scrollToSelectedIndex();
        isHandle = true;
      } else if (logicalKey == PhysicalKeyboardKey.enter) {
        widget.handler.onSelected(widget.pages[_selectedIndex]);
        widget.onDismiss?.call();
        isHandle = true;
      } else if (logicalKey == PhysicalKeyboardKey.escape) {
        widget.onDismiss?.call();
        isHandle = true;
      }
    });
    return isHandle ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatInputActionBloc, ChatInputActionState>(
      listenWhen: (previous, current) =>
          previous.keyboardKey != current.keyboardKey,
      listener: (context, state) {
        if (state.keyboardKey != null) {
          _handleKeyPress(state.keyboardKey!.physicalKey);
        }
      },
      child: ListView(
        shrinkWrap: true,
        controller: _scrollController,
        padding: const EdgeInsets.all(4),
        children: _buildPages(),
      ),
    );
  }

  List<Widget> _buildPages() {
    if (widget.isLoading) {
      return [
        SizedBox(
          height: _noPageHeight.toDouble(),
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
      ];
    }

    if (widget.pages.isEmpty) {
      return [
        SizedBox(
          height: _noPageHeight.toDouble(),
          child:
              Center(child: FlowyText(LocaleKeys.chat_inputActionNoPages.tr())),
        ),
      ];
    }

    return widget.pages.asMap().entries.map((entry) {
      final index = entry.key;
      final ChatInputMention item = entry.value;
      return AutoScrollTag(
        key: ValueKey(item.pageId),
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
    }).toList();
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
