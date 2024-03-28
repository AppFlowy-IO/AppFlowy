import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/document_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

typedef OnDocumentEventUpdate = void Function(DocEventPB docEvent);
typedef OnDocumentAwarenessStateUpdate = void Function(
  DocumentAwarenessStatesPB awarenessStates,
);

class DocumentListener {
  DocumentListener({
    required this.id,
  });

  final String id;

  StreamSubscription<SubscribeObject>? _subscription;
  DocumentNotificationParser? _parser;

  OnDocumentEventUpdate? _onDocEventUpdate;
  OnDocumentAwarenessStateUpdate? _onDocAwarenessUpdate;

  void start({
    OnDocumentEventUpdate? onDocEventUpdate,
    OnDocumentAwarenessStateUpdate? onDocAwarenessUpdate,
  }) {
    _onDocEventUpdate = onDocEventUpdate;
    _onDocAwarenessUpdate = onDocAwarenessUpdate;

    _parser = DocumentNotificationParser(
      id: id,
      callback: _callback,
    );
    _subscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  void _callback(
    DocumentNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DocumentNotification.DidReceiveUpdate:
        result.map(
          (s) => _onDocEventUpdate?.call(DocEventPB.fromBuffer(s)),
        );
        break;
      case DocumentNotification.DidUpdateDocumentAwarenessState:
        result.map(
          (s) => _onDocAwarenessUpdate?.call(
            DocumentAwarenessStatesPB.fromBuffer(s),
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _onDocAwarenessUpdate = null;
    _onDocEventUpdate = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
