import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

const int _itemHeight = 44;
const int _itemVerticalPadding = 4;
const int _noPageHeight = 20;

abstract class ChatActionHandler {
  void onEnter();
  void onSelected(ViewPB page);
  void onExit();
  ChatInputActionBloc get commandBloc;
  void onFilter(String filter);
  double actionMenuOffsetX();
}

class ChatInputAnchor {
  ChatInputAnchor({
    required this.anchorKey,
    required this.layerLink,
  });

  final GlobalKey<State<StatefulWidget>> anchorKey;
  final LayerLink layerLink;
}

class ChatActionsMenu {
  ChatActionsMenu({
    required this.anchor,
    required this.context,
    required this.handler,
  });

  final BuildContext context;
  final ChatInputAnchor anchor;
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
    const maxHeight = 600.0;

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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 360,
                      maxWidth: 360,
                      maxHeight: maxHeight,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A1F2329),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: Color(0x0A1F2329),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Color(0x0F1F2329),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                            spreadRadius: -8,
                          ),
                        ],
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

  final ViewPB item;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: item.name,
      child: Container(
        height: _itemHeight.toDouble(),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.all(4.0),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              item.defaultIcon(),
              const HSpace(8.0),
              Expanded(
                child: FlowyText(
                  item.name.isEmpty
                      ? LocaleKeys.document_title_placeholder.tr()
                      : item.name,
                  lineHeight: 1.0,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
  final List<ViewPB> pages;
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
        padding: const EdgeInsets.all(8.0),
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
      final ViewPB item = entry.value;
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
