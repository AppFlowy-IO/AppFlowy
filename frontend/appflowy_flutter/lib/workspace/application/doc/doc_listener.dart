import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/document_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';

class DocumentListener {
  DocumentListener({
    required this.id,
  });

  final String id;

  final _didReceiveUpdate = PublishNotifier();
  StreamSubscription<SubscribeObject>? _subscription;
  DocumentNotificationParser? _parser;

  Function()? didReceiveUpdate;

  void start({
    void Function()? didReceiveUpdate,
  }) {
    this.didReceiveUpdate = didReceiveUpdate;

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
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DocumentNotification.DidReceiveUpdate:
        didReceiveUpdate?.call();
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
  }
}
