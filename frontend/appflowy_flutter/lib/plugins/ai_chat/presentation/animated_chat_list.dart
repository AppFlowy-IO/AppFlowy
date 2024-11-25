// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:math';

import 'package:diffutil_dart/diffutil.dart' as diffutil;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';

import 'package:flutter_chat_ui/src/scroll_to_bottom.dart';
import 'package:flutter_chat_ui/src/utils/message_list_diff.dart';

class ChatAnimatedListReversed extends StatefulWidget {
  const ChatAnimatedListReversed({
    super.key,
    required this.scrollController,
    required this.itemBuilder,
    this.insertAnimationDuration = const Duration(milliseconds: 250),
    this.removeAnimationDuration = const Duration(milliseconds: 250),
    this.scrollToEndAnimationDuration = const Duration(milliseconds: 250),
    this.scrollToBottomAppearanceDelay = const Duration(milliseconds: 250),
    this.bottomPadding = 8,
    this.onLoadPreviousMessages,
  });

  final ScrollController scrollController;
  final ChatItem itemBuilder;
  final Duration insertAnimationDuration;
  final Duration removeAnimationDuration;
  final Duration scrollToEndAnimationDuration;
  final Duration scrollToBottomAppearanceDelay;
  final double? bottomPadding;
  final VoidCallback? onLoadPreviousMessages;

  @override
  ChatAnimatedListReversedState createState() =>
      ChatAnimatedListReversedState();
}

class ChatAnimatedListReversedState extends State<ChatAnimatedListReversed>
    with SingleTickerProviderStateMixin {
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();
  late ChatController _chatController;
  late List<Message> _oldList;
  late StreamSubscription<ChatOperation> _operationsSubscription;

  late final AnimationController _scrollToBottomController;
  late final Animation<double> _scrollToBottomAnimation;
  Timer? _scrollToBottomShowTimer;

  bool _userHasScrolled = false;
  bool _isScrollingToBottom = false;
  String _lastInsertedMessageId = '';

  @override
  void initState() {
    super.initState();
    _chatController = Provider.of<ChatController>(context, listen: false);
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
          _onInserted(0, event.message!);
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

    widget.scrollController.addListener(_handleLoadPreviousMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLoadPreviousMessages();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollToBottomShowTimer?.cancel();
    _scrollToBottomController.dispose();
    _operationsSubscription.cancel();
    widget.scrollController.removeListener(_handleLoadPreviousMessages);
  }

  @override
  Widget build(BuildContext context) {
    final builders = context.watch<Builders>();

    return NotificationListener<Notification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification) {
          // When user scrolls up, save it to `_userHasScrolled`
          if (notification.direction == ScrollDirection.reverse) {
            _userHasScrolled = true;
          } else {
            // When user overscolls to the bottom or stays idle at the bottom, set `_userHasScrolled` to false
            if (notification.metrics.pixels ==
                notification.metrics.minScrollExtent) {
              _userHasScrolled = false;
            }
          }
        }

        if (notification is ScrollUpdateNotification) {
          _handleToggleScrollToBottom();
        }

        // Allow other listeners to get the notification
        return false;
      },
      child: Stack(
        children: [
          CustomScrollView(
            reverse: true,
            controller: widget.scrollController,
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.only(
                  top: widget.bottomPadding ?? 0,
                ),
              ),
              SliverAnimatedList(
                key: _listKey,
                initialItemCount: _chatController.messages.length,
                itemBuilder: (
                  BuildContext context,
                  int index,
                  Animation<double> animation,
                ) {
                  final message = _chatController.messages[
                      max(_chatController.messages.length - 1 - index, 0)];
                  return widget.itemBuilder(
                    context,
                    animation,
                    message,
                  );
                },
              ),
            ],
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
      ),
    );
  }

  void _subsequentScrollToEnd(Message data) async {
    final user = Provider.of<User>(context, listen: false);

    // We only want to scroll to the bottom if user has not scrolled up
    // or if the message is sent by the current user.
    if (data.id == _lastInsertedMessageId &&
        widget.scrollController.offset >
            widget.scrollController.position.minScrollExtent &&
        (user.id == data.author.id || !_userHasScrolled)) {
      if (widget.scrollToEndAnimationDuration == Duration.zero) {
        widget.scrollController
            .jumpTo(widget.scrollController.position.minScrollExtent);
      } else {
        await widget.scrollController.animateTo(
          widget.scrollController.position.minScrollExtent,
          duration: widget.scrollToEndAnimationDuration,
          curve: Curves.linearToEaseOut,
        );
      }

      if (!widget.scrollController.hasClients || !mounted) return;

      // Because of the issue I have opened here https://github.com/flutter/flutter/issues/129768
      // we need an additional jump to the end. Sometimes Flutter
      // will not scroll to the very end. Sometimes it will not scroll to the
      // very end even with this, so this is something that needs to be
      // addressed by the Flutter team.
      //
      // Additionally here we have a check for the message id, because
      // if new message arrives in the meantime it will trigger another
      // scroll to the end animation, making this logic redundant.
      if (data.id == _lastInsertedMessageId &&
          widget.scrollController.offset >
              widget.scrollController.position.minScrollExtent &&
          (user.id == data.author.id || !_userHasScrolled)) {
        widget.scrollController
            .jumpTo(widget.scrollController.position.minScrollExtent);
      }
    }
  }

  void _scrollToEnd(Message data) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!widget.scrollController.hasClients || !mounted) return;

        _subsequentScrollToEnd(data);
      },
    );
  }

  void _handleScrollToBottom() {
    _isScrollingToBottom = true;
    _scrollToBottomController.reverse();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.scrollController.hasClients || !mounted) return;

      if (widget.scrollToEndAnimationDuration == Duration.zero) {
        widget.scrollController
            .jumpTo(widget.scrollController.position.minScrollExtent);
      } else {
        await widget.scrollController.animateTo(
          widget.scrollController.position.minScrollExtent,
          duration: widget.scrollToEndAnimationDuration,
          curve: Curves.linearToEaseOut,
        );
      }

      if (!widget.scrollController.hasClients || !mounted) return;

      if (widget.scrollController.offset <
          widget.scrollController.position.minScrollExtent) {
        widget.scrollController.jumpTo(
          widget.scrollController.position.minScrollExtent,
        );
      }

      _isScrollingToBottom = false;
    });
  }

  void _handleToggleScrollToBottom() {
    if (_isScrollingToBottom) {
      return;
    }

    _scrollToBottomShowTimer?.cancel();
    if (widget.scrollController.offset >
        widget.scrollController.position.minScrollExtent) {
      _scrollToBottomShowTimer =
          Timer(widget.scrollToBottomAppearanceDelay, () {
        if (mounted) {
          _scrollToBottomController.forward();
        }
      });
    } else {
      if (_scrollToBottomController.status != AnimationStatus.completed) {
        _scrollToBottomController.stop();
      }
      _scrollToBottomController.reverse();
    }
  }

  void _onInserted(final int position, final Message data) {
    // There is a scroll notification listener the controls the
    // `_userHasScrolled` variable.
    //
    // If for some reason `_userHasScrolled` is true and the user is not at the
    // bottom of the list, set `_userHasScrolled` to false so that the scroll
    // animation is triggered.
    if (_userHasScrolled &&
        widget.scrollController.offset >=
            widget.scrollController.position.minScrollExtent) {
      _userHasScrolled = false;
    }

    _listKey.currentState!.insertItem(
      position,
      duration: widget.insertAnimationDuration,
    );

    // Used later to trigger scroll to end only for the last inserted message.
    _lastInsertedMessageId = data.id;

    if (position == _oldList.length) {
      _scrollToEnd(data);
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

  void _handleLoadPreviousMessages() {
    if (widget.scrollController.offset >=
        widget.scrollController.position.maxScrollExtent) {
      widget.onLoadPreviousMessages?.call();
    }
  }
}
