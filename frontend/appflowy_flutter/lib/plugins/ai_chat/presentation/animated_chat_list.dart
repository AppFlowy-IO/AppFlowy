// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:appflowy/util/debounce.dart';
import 'package:appflowy_backend/log.dart';
import 'package:diffutil_dart/diffutil.dart' as diffutil;
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/src/scroll_to_bottom.dart';
import 'package:flutter_chat_ui/src/utils/message_list_diff.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../application/chat_message_height_manager.dart';
import 'widgets/message_height_calculator.dart';

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
  State<ChatAnimatedList> createState() => _ChatAnimatedListState();
}

class _ChatAnimatedListState extends State<ChatAnimatedList>
    with SingleTickerProviderStateMixin {
  late final ChatController chatController = Provider.of<ChatController>(
    context,
    listen: false,
  );
  late List<Message> oldList;
  late StreamSubscription<ChatOperation> operationsSubscription;

  late final AnimationController scrollToBottomController;
  late final Animation<double> scrollToBottomAnimation;
  Timer? scrollToBottomShowTimer;

  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();

  final ItemScrollController itemScrollController = ItemScrollController();

  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  int lastUserMessageIndex = 0;
  bool isScrollingToBottom = false;

  final loadPreviousMessagesDebounce = Debounce(
    duration: const Duration(milliseconds: 200),
  );

  int initialScrollIndex = 0;
  double initialAlignment = 1.0;
  List<Message> messages = [];

  final ChatMessageHeightManager heightManager = ChatMessageHeightManager();

  @override
  void initState() {
    super.initState();

    // TODO: Add assert for messages having same id
    oldList = List.from(chatController.messages);
    operationsSubscription = chatController.operationsStream.listen((event) {
      setState(() {
        messages = chatController.messages;
      });
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
          oldList = List.from(chatController.messages);
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
          oldList = List.from(chatController.messages);
          break;
        case ChatOperationType.set:
          final newList = chatController.messages;

          final updates = diffutil
              .calculateDiff<Message>(
                MessageListDiff(oldList, newList),
              )
              .getUpdatesWithData();

          for (var i = updates.length - 1; i >= 0; i--) {
            _onDiffUpdate(updates.elementAt(i));
          }

          oldList = List.from(newList);
          break;
        default:
          break;
      }
    });

    messages = chatController.messages;

    scrollToBottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    scrollToBottomAnimation = CurvedAnimation(
      parent: scrollToBottomController,
      curve: Curves.easeInOut,
    );

    itemPositionsListener.itemPositions.addListener(() {
      _handleToggleScrollToBottom();
    });

    itemPositionsListener.itemPositions.addListener(() {
      _handleLoadPreviousMessages();
    });
  }

  @override
  void dispose() {
    scrollToBottomShowTimer?.cancel();
    scrollToBottomController.dispose();
    operationsSubscription.cancel();

    _clearMessageHeightCache();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builders = context.watch<Builders>();

    // A trick to avoid the first message being scrolled to the top
    initialScrollIndex = messages.length;
    initialAlignment = 1.0;
    if (messages.length <= 2) {
      initialScrollIndex = 0;
      initialAlignment = 0.0;
    }

    final Widget child = Stack(
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
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index < 0 || index > messages.length) {
              Log.error('[chat animation list] index out of range: $index');
              return const SizedBox.shrink();
            }

            if (index == messages.length) {
              return const SizedBox.shrink();
            }

            final message = messages[index];
            return MessageHeightCalculator(
              messageId: message.id,
              onHeightMeasured: _cacheMessageHeight,
              child: widget.itemBuilder(
                context,
                Tween<double>(begin: 1, end: 1).animate(
                  CurvedAnimation(
                    parent: scrollToBottomController,
                    curve: Curves.easeInOut,
                  ),
                ),
                message,
              ),
            );
          },
        ),
        builders.scrollToBottomBuilder?.call(
              context,
              scrollToBottomAnimation,
              _handleScrollToBottom,
            ) ??
            ScrollToBottom(
              animation: scrollToBottomAnimation,
              onPressed: _handleScrollToBottom,
            ),
      ],
    );

    return child;
  }

  Future<void> _scrollLastUserMessageToTop() async {
    final user = Provider.of<User>(context, listen: false);
    final lastUserMessageIndex = messages.lastIndexWhere(
      (message) => message.author.id == user.id,
    );

    // waiting for the ai answer message to be inserted
    if (lastUserMessageIndex == -1 ||
        lastUserMessageIndex + 1 >= messages.length) {
      return;
    }

    if (this.lastUserMessageIndex != lastUserMessageIndex) {
      // scroll the current message to the top
      await itemScrollController.scrollTo(
        index: lastUserMessageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    this.lastUserMessageIndex = lastUserMessageIndex;
  }

  Future<void> _handleScrollToBottom() async {
    isScrollingToBottom = true;

    scrollToBottomShowTimer?.cancel();

    await scrollToBottomController.reverse();

    await itemScrollController.scrollTo(
      index: messages.length + 1,
      alignment: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    isScrollingToBottom = false;
  }

  void _handleToggleScrollToBottom() {
    if (isScrollingToBottom) {
      return;
    }

    // get the max item
    final sortedItems = itemPositionsListener.itemPositions.value.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final maxItem = sortedItems.lastOrNull;

    if (maxItem == null) {
      return;
    }

    if (maxItem.index > messages.length - 1 ||
        (maxItem.index == messages.length - 1 &&
            maxItem.itemTrailingEdge <= 1.01)) {
      scrollToBottomShowTimer?.cancel();
      scrollToBottomController.reverse();
      return;
    }

    scrollToBottomShowTimer?.cancel();
    scrollToBottomShowTimer = Timer(widget.scrollToBottomAppearanceDelay, () {
      if (mounted) {
        scrollToBottomController.forward();
      }
    });
  }

  void _handleLoadPreviousMessages() {
    final sortedItems = itemPositionsListener.itemPositions.value.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final minItem = sortedItems.firstOrNull;

    if (minItem == null || minItem.index > 0 || minItem.itemLeadingEdge < 0) {
      return;
    }

    loadPreviousMessagesDebounce.call(
      () {
        widget.onLoadPreviousMessages?.call();
      },
    );
  }

  void _cacheMessageHeight(String messageId, double height) {
    heightManager.cacheHeight(messageId: messageId, height: height);
  }

  void _clearMessageHeightCache() {
    heightManager.clearCache();
  }

  Future<void> _onInserted(final int position, final Message data) async {
    // scroll the last user message to the top if it's the last message
    if (position == oldList.length) {
      await _scrollLastUserMessageToTop();
    }
  }

  void _onRemoved(final int position, final Message data) {
    // Clean up cached height for removed message
    heightManager.removeFromCache(messageId: data.id);
  }

  void _onDiffUpdate(diffutil.DataDiffUpdate<Message> update) {
    // do nothing
  }
}
