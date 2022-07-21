import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';

typedef DeleteViewNotifyValue = Either<ViewPB, FlowyError>;
typedef UpdateViewNotifiedValue = Either<ViewPB, FlowyError>;
typedef RestoreViewNotifiedValue = Either<ViewPB, FlowyError>;

class ViewListener {
  StreamSubscription<SubscribeObject>? _subscription;
  final PublishNotifier<UpdateViewNotifiedValue> _updatedViewNotifier = PublishNotifier();
  final PublishNotifier<DeleteViewNotifyValue> _deletedNotifier = PublishNotifier();
  final PublishNotifier<RestoreViewNotifiedValue> _restoredNotifier = PublishNotifier();
  FolderNotificationParser? _parser;
  ViewPB view;

  ViewListener({
    required this.view,
  });

  void start({
    void Function(UpdateViewNotifiedValue)? onViewUpdated,
    void Function(DeleteViewNotifyValue)? onViewDeleted,
    void Function(RestoreViewNotifiedValue)? onViewRestored,
  }) {
    if (onViewUpdated != null) {
      _updatedViewNotifier.addListener(() {
        onViewUpdated(_updatedViewNotifier.currentValue!);
      });
    }

    if (onViewDeleted != null) {
      _deletedNotifier.addListener(() {
        onViewDeleted(_deletedNotifier.currentValue!);
      });
    }

    if (onViewRestored != null) {
      _restoredNotifier.addListener(() {
        onViewRestored(_restoredNotifier.currentValue!);
      });
    }

    _parser = FolderNotificationParser(
      id: view.id,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleObservableType(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.ViewUpdated:
        result.fold(
          (payload) => _updatedViewNotifier.value = left(ViewPB.fromBuffer(payload)),
          (error) => _updatedViewNotifier.value = right(error),
        );
        break;
      case FolderNotification.ViewDeleted:
        result.fold(
          (payload) => _deletedNotifier.value = left(ViewPB.fromBuffer(payload)),
          (error) => _deletedNotifier.value = right(error),
        );
        break;
      case FolderNotification.ViewRestored:
        result.fold(
          (payload) => _restoredNotifier.value = left(ViewPB.fromBuffer(payload)),
          (error) => _restoredNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _updatedViewNotifier.dispose();
    _deletedNotifier.dispose();
    _restoredNotifier.dispose();
  }
}
