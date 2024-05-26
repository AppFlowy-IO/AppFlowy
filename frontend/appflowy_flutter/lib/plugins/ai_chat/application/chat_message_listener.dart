import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'chat_notification.dart';

typedef ChatMessageCallback = void Function(
  ChatMessagePB message,
);

typedef ChatErrorMessageCallback = void Function(
  ChatMessageErrorPB message,
);

class ChatMessageListener {
  ChatMessageListener({
    required this.chatId,
  }) {
    _parser = ChatNotificationParser(
      id: chatId,
      callback: _callback,
    );
    _subscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  final String chatId;
  StreamSubscription<SubscribeObject>? _subscription;
  ChatNotificationParser? _parser;
  ChatMessageCallback? chatMessageCallback;
  ChatErrorMessageCallback? chatErrorMessageCallback;
  void Function()? finishAnswerQuestionCallback;

  void start({
    ChatMessageCallback? chatMessageCallback,
    ChatErrorMessageCallback? chatErrorMessageCallback,
    void Function()? finishAnswerQuestionCallback,
  }) {
    this.chatMessageCallback = chatMessageCallback;
    this.chatErrorMessageCallback = chatErrorMessageCallback;
    this.finishAnswerQuestionCallback = finishAnswerQuestionCallback;
  }

  void _callback(
    ChatNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case ChatNotification.DidReceiveChatMessage:
        result.map(
          (r) {
            final value = ChatMessagePB.fromBuffer(r);
            chatMessageCallback?.call(value);
          },
        );
        break;
      case ChatNotification.ChatMessageError:
        result.map(
          (r) {
            final value = ChatMessageErrorPB.fromBuffer(r);
            chatErrorMessageCallback?.call(value);
          },
        );
        break;
      case ChatNotification.FinishAnswerQuestion:
        finishAnswerQuestionCallback?.call();
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
