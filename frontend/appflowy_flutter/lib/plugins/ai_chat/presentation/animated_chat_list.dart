// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:math';

import 'package:appflowy_backend/log.dart';
import 'package:diffutil_dart/diffutil.dart' as diffutil;
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/src/scroll_to_bottom.dart';
import 'package:flutter_chat_ui/src/utils/message_list_diff.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatAnimatedList extends StatefulWidget {
  const ChatAnimatedList({
    super.key,
    required this.scrollController,
    required this.itemBuilder,
    this.insertAnimationDuration = const Duration(milliseconds: 250),
    this.removeAnimationDuration = const Duration(milliseconds: 250),
    this.scrollToEndAnimationDuration = const Duration(milliseconds: 250),
    this.scrollToBottomAppearanceDelay = const Duration(milliseconds: 250),
    this.bottomPadding = 8,
    this.onLoadPreviousMessages,
    this.scrollBottomPadding = 440,
  });

  final ScrollController scrollController;
  final ChatItem itemBuilder;
  final Duration insertAnimationDuration;
  final Duration removeAnimationDuration;
  final Duration scrollToEndAnimationDuration;
  final Duration scrollToBottomAppearanceDelay;
  final double? bottomPadding;
  final VoidCallback? onLoadPreviousMessages;
  final double scrollBottomPadding;

  @override
  ChatAnimatedListState createState() => ChatAnimatedListState();
}

class ChatAnimatedListState extends State<ChatAnimatedList>
    with SingleTickerProviderStateMixin {
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();
  late final ChatController _chatController = Provider.of<ChatController>(
    context,
    listen: false,
  );
  late List<Message> _oldList;
  late StreamSubscription<ChatOperation> _operationsSubscription;

  late final AnimationController _scrollToBottomController;
  late final Animation<double> _scrollToBottomAnimation;
  Timer? _scrollToBottomShowTimer;

  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();

  final ItemScrollController itemScrollController = ItemScrollController();

  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  int _lastUserMessageIndex = 0;
  bool _isScrollingToBottom = false;

  @override
  void initState() {
    super.initState();

    // TODO: Add assert for messages having same id
    _oldList = List.from(_chatController.messages);
    _operationsSubscription = _chatController.operationsStream.listen((event) {
      switch (event.type) {
        case ChatOperationType.insert:
          assert(
            event.index != null,
            'Index must be provided when inserting a message.',
          );
          assert(
            event.message != null,
            'Message must be provided when inserting a message.',
          );
          _onInserted(event.index!, event.message!);
          _oldList = List.from(_chatController.messages);
          break;
        case ChatOperationType.remove:
          assert(
            event.index != null,
            'Index must be provided when removing a message.',
          );
          assert(
            event.message != null,
            'Message must be provided when removing a message.',
          );
          _onRemoved(event.index!, event.message!);
          _oldList = List.from(_chatController.messages);
          break;
        case ChatOperationType.set:
          final newList = _chatController.messages;

          final updates = diffutil
              .calculateDiff<Message>(
                MessageListDiff(_oldList, newList),
              )
              .getUpdatesWithData();

          for (var i = updates.length - 1; i >= 0; i--) {
            _onDiffUpdate(updates.elementAt(i));
          }

          _oldList = List.from(newList);
          break;
        default:
          break;
      }
    });

    _scrollToBottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scrollToBottomAnimation = CurvedAnimation(
      parent: _scrollToBottomController,
      curve: Curves.easeInOut,
    );

    itemPositionsListener.itemPositions.addListener(() {
      _handleToggleScrollToBottom();
    });
  }

  @override
  void dispose() {
    super.dispose();

    _scrollToBottomShowTimer?.cancel();
    _scrollToBottomController.dispose();
    _operationsSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final builders = context.watch<Builders>();
    final height = MediaQuery.of(context).size.height;

    // A trick to avoid the first message being scrolled to the top
    int initialScrollIndex = _chatController.messages.length;
    double initialAlignment = 1.0;
    if (_chatController.messages.length <= 2) {
      initialScrollIndex = 0;
      initialAlignment = 0.0;
    }

    return Stack(
      children: [
        ScrollablePositionedList.builder(
          scrollOffsetController: scrollOffsetController,
          itemScrollController: itemScrollController,
          initialScrollIndex: initialScrollIndex,
          initialAlignment: initialAlignment,
          scrollOffsetListener: scrollOffsetListener,
          itemPositionsListener: itemPositionsListener,
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          // the extra item is a vertical padding.
          itemCount: _chatController.messages.length + 1,
          itemBuilder: (context, index) {
            if (index < 0 || index > _chatController.messages.length) {
              return SizedBox.shrink();
            }

            if (index == _chatController.messages.length) {
              return VSpace(height - 400);
            }

            final message = _chatController.messages[index];
            return widget.itemBuilder(
              context,
              Tween<double>(begin: 1, end: 1).animate(
                CurvedAnimation(
                  parent: _scrollToBottomController,
                  curve: Curves.easeInOut,
                ),
              ),
              message,
            );
          },
        ),
        builders.scrollToBottomBuilder?.call(
              context,
              _scrollToBottomAnimation,
              _handleScrollToBottom,
            ) ??
            ScrollToBottom(
              animation: _scrollToBottomAnimation,
              onPressed: _handleScrollToBottom,
            ),
      ],
    );
  }

  void _scrollLastMessageToTop(Message data) {
    final user = Provider.of<User>(context, listen: false);
    final lastUserMessageIndex = _chatController.messages.lastIndexWhere(
      (message) => message.author.id == user.id,
    );

    if (_lastUserMessageIndex != lastUserMessageIndex) {
      // scroll the current message to the top
      Log.info('scrolling the last message to the top');
      itemScrollController.scrollTo(
        index: lastUserMessageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    _lastUserMessageIndex = lastUserMessageIndex;
  }

  Future<void> _handleScrollToBottom() async {
    _isScrollingToBottom = true;

    _scrollToBottomShowTimer?.cancel();

    await _scrollToBottomController.reverse();

    await itemScrollController.scrollTo(
      index: _chatController.messages.length + 1,
      alignment: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _isScrollingToBottom = false;
  }

  void _handleToggleScrollToBottom() {
    if (_isScrollingToBottom) {
      return;
    }

    // get the max item
    final sortedItems = itemPositionsListener.itemPositions.value.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final maxItem = sortedItems.last;

    if (maxItem.index >= _chatController.messages.length - 1) {
      _scrollToBottomShowTimer?.cancel();
      _scrollToBottomController.reverse();
      return;
    }

    _scrollToBottomShowTimer?.cancel();
    _scrollToBottomShowTimer = Timer(widget.scrollToBottomAppearanceDelay, () {
      if (mounted) {
        _scrollToBottomController.forward();
      }
    });
  }

  void _onInserted(final int position, final Message data) {
    if (position == _oldList.length) {
      _scrollLastMessageToTop(data);
    }
  }

  void _onRemoved(final int position, final Message data) {
    final visualPosition = max(_oldList.length - position - 1, 0);
    _listKey.currentState!.removeItem(
      visualPosition,
      (context, animation) => widget.itemBuilder(
        context,
        animation,
        data,
        isRemoved: true,
      ),
      duration: widget.removeAnimationDuration,
    );
  }

  void _onChanged(int position, Message oldData, Message newData) {
    _onRemoved(position, oldData);
    _listKey.currentState!.insertItem(
      max(_oldList.length - position - 1, 0),
      duration: widget.insertAnimationDuration,
    );
  }

  void _onDiffUpdate(diffutil.DataDiffUpdate<Message> update) {
    update.when<void>(
      insert: (pos, data) => _onInserted(max(_oldList.length - pos, 0), data),
      remove: (pos, data) => _onRemoved(pos, data),
      change: (pos, oldData, newData) => _onChanged(pos, oldData, newData),
      move: (_, __, ___) => throw UnimplementedError('unused'),
    );
  }
}
