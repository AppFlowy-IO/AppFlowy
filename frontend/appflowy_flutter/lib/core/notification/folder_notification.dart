import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'notification_helper.dart';

// This value should be the same as the FOLDER_OBSERVABLE_SOURCE value
const String _source = 'Folder';

class FolderNotificationParser
    extends NotificationParser<FolderNotification, FlowyError> {
  FolderNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty, source) =>
              source == _source ? FolderNotification.valueOf(ty) : null,
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef FolderNotificationHandler = void Function(
  FolderNotification ty,
  FlowyResult<Uint8List, FlowyError> result,
);

typedef FolderDidUpdateFolderPagesHandler = void Function(
  FlowyResult<FolderPageNotificationPayloadPB, FlowyError> result,
);

class FolderNotificationListener {
  FolderNotificationListener({
    required String objectId,
    this.didUpdateFolderPagesNotifier,
  }) {
    _parser = FolderNotificationParser(
      id: objectId,
      callback: callback,
    );
    _subscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  /// This handler will be called when the folder pages are updated.
  final FolderDidUpdateFolderPagesHandler? didUpdateFolderPagesNotifier;

  FolderNotificationParser? _parser;
  StreamSubscription<SubscribeObject>? _subscription;

  void callback(
    FolderNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateFolderPages:
        final response = result
            .fold<FlowyResult<FolderPageNotificationPayloadPB, FlowyError>>(
          (payload) => FlowyResult.success(
            FolderPageNotificationPayloadPB.fromBuffer(payload),
          ),
          (error) => FlowyResult.failure(error),
        );
        didUpdateFolderPagesNotifier?.call(response);
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
