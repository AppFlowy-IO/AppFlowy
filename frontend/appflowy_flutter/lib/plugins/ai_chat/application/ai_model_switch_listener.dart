import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/plugins/ai_chat/application/chat_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

typedef OnUpdateSelectedModel = void Function(AIModelPB model);

class AIModelSwitchListener {
  AIModelSwitchListener({required this.chatId}) {
    _parser = ChatNotificationParser(id: chatId, callback: _callback);
    _subscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  final String chatId;
  StreamSubscription<SubscribeObject>? _subscription;
  ChatNotificationParser? _parser;

  void start({
    OnUpdateSelectedModel? onUpdateSelectedModel,
  }) {
    this.onUpdateSelectedModel = onUpdateSelectedModel;
  }

  OnUpdateSelectedModel? onUpdateSelectedModel;

  void _callback(
    ChatNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    result.map((r) {
      switch (ty) {
        case ChatNotification.DidUpdateSelectedModel:
          onUpdateSelectedModel?.call(AIModelPB.fromBuffer(r));
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
