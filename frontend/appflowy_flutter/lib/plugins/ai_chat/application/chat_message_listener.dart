import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'chat_notification.dart';

typedef ChatMessageCallback = void Function(ChatMessagePB message);
typedef ChatErrorMessageCallback = void Function(ChatMessageErrorPB message);
typedef LatestMessageCallback = void Function(ChatMessageListPB list);
typedef PrevMessageCallback = void Function(ChatMessageListPB list);

class ChatMessageListener {
  ChatMessageListener({required this.chatId}) {
    _parser = ChatNotificationParser(id: chatId, callback: _callback);
    _subscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  final String chatId;
  StreamSubscription<SubscribeObject>? _subscription;
  ChatNotificationParser? _parser;

  ChatMessageCallback? chatMessageCallback;
  ChatErrorMessageCallback? chatErrorMessageCallback;
  LatestMessageCallback? latestMessageCallback;
  PrevMessageCallback? prevMessageCallback;
  void Function()? finishStreamingCallback;

  void start({
    ChatMessageCallback? chatMessageCallback,
    ChatErrorMessageCallback? chatErrorMessageCallback,
    LatestMessageCallback? latestMessageCallback,
    PrevMessageCallback? prevMessageCallback,
    void Function()? finishStreamingCallback,
  }) {
    this.chatMessageCallback = chatMessageCallback;
    this.chatErrorMessageCallback = chatErrorMessageCallback;
    this.latestMessageCallback = latestMessageCallback;
    this.prevMessageCallback = prevMessageCallback;
    this.finishStreamingCallback = finishStreamingCallback;
  }

  void _callback(
    ChatNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    result.map((r) {
      switch (ty) {
        case ChatNotification.DidReceiveChatMessage:
          chatMessageCallback?.call(ChatMessagePB.fromBuffer(r));
          break;
        case ChatNotification.StreamChatMessageError:
          chatErrorMessageCallback?.call(ChatMessageErrorPB.fromBuffer(r));
          break;
        case ChatNotification.DidLoadLatestChatMessage:
          latestMessageCallback?.call(ChatMessageListPB.fromBuffer(r));
          break;
        case ChatNotification.DidLoadPrevChatMessage:
          prevMessageCallback?.call(ChatMessageListPB.fromBuffer(r));
          break;
        case ChatNotification.FinishStreaming:
          finishStreamingCallback?.call();
          break;
        default:
          break;
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
