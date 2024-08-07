import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/plugins/ai_chat/application/chat_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

typedef PluginStateCallback = void Function(LocalAIPluginStatePB state);
typedef LocalAIChatCallback = void Function(LocalAIChatPB chatState);

class LocalLLMListener {
  LocalLLMListener() {
    _parser =
        ChatNotificationParser(id: "appflowy_ai_plugin", callback: _callback);
    _subscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  StreamSubscription<SubscribeObject>? _subscription;
  ChatNotificationParser? _parser;

  PluginStateCallback? stateCallback;
  LocalAIChatCallback? chatStateCallback;
  void Function()? finishStreamingCallback;

  void start({
    PluginStateCallback? stateCallback,
    LocalAIChatCallback? chatStateCallback,
  }) {
    this.stateCallback = stateCallback;
    this.chatStateCallback = chatStateCallback;
  }

  void _callback(
    ChatNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    result.map((r) {
      switch (ty) {
        case ChatNotification.UpdateChatPluginState:
          stateCallback?.call(LocalAIPluginStatePB.fromBuffer(r));
          break;
        case ChatNotification.UpdateLocalChatAI:
          chatStateCallback?.call(LocalAIChatPB.fromBuffer(r));
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
