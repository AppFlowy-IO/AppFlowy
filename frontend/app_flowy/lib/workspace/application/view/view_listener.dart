import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';

typedef DeleteViewNotifyValue = Either<View, FlowyError>;
typedef UpdateViewNotifiedValue = Either<View, FlowyError>;
typedef RestoreViewNotifiedValue = Either<View, FlowyError>;

class ViewListener {
  StreamSubscription<SubscribeObject>? _subscription;
  PublishNotifier<UpdateViewNotifiedValue> updatedNotifier = PublishNotifier<UpdateViewNotifiedValue>();
  PublishNotifier<DeleteViewNotifyValue> deletedNotifier = PublishNotifier<DeleteViewNotifyValue>();
  PublishNotifier<RestoreViewNotifiedValue> restoredNotifier = PublishNotifier<RestoreViewNotifiedValue>();
  late FolderNotificationParser _parser;
  View view;

  ViewListener({
    required this.view,
  });

  void start() {
    _parser = FolderNotificationParser(
      id: view.id,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _handleObservableType(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.ViewUpdated:
        result.fold(
          (payload) => updatedNotifier.value = left(View.fromBuffer(payload)),
          (error) => updatedNotifier.value = right(error),
        );
        break;
      case FolderNotification.ViewDeleted:
        result.fold(
          (payload) => deletedNotifier.value = left(View.fromBuffer(payload)),
          (error) => deletedNotifier.value = right(error),
        );
        break;
      case FolderNotification.ViewRestored:
        result.fold(
          (payload) => restoredNotifier.value = left(View.fromBuffer(payload)),
          (error) => restoredNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    updatedNotifier.dispose();
    deletedNotifier.dispose();
    restoredNotifier.dispose();
  }
}
