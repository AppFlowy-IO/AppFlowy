import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';

import 'helper.dart';

class ViewRepository {
  View view;
  ViewRepository({
    required this.view,
  });

  Future<Either<View, FlowyError>> readView() {
    final request = QueryViewRequest(viewIds: [view.id]);
    return FolderEventReadView(request).send();
  }

  Future<Either<View, FlowyError>> updateView({String? name, String? desc}) {
    final request = UpdateViewRequest.create()..viewId = view.id;

    if (name != null) {
      request.name = name;
    }

    if (desc != null) {
      request.desc = desc;
    }

    return FolderEventUpdateView(request).send();
  }

  Future<Either<Unit, FlowyError>> delete() {
    final request = QueryViewRequest.create()..viewIds.add(view.id);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<Unit, FlowyError>> duplicate() {
    final request = QueryViewRequest.create()..viewIds.add(view.id);
    return FolderEventDuplicateView(request).send();
  }
}

typedef DeleteNotifierValue = Either<View, FlowyError>;
typedef UpdateNotifierValue = Either<View, FlowyError>;
typedef RestoreNotifierValue = Either<View, FlowyError>;

class ViewListener {
  StreamSubscription<SubscribeObject>? _subscription;
  PublishNotifier<UpdateNotifierValue> updatedNotifier = PublishNotifier<UpdateNotifierValue>();
  PublishNotifier<DeleteNotifierValue> deletedNotifier = PublishNotifier<DeleteNotifierValue>();
  PublishNotifier<RestoreNotifierValue> restoredNotifier = PublishNotifier<RestoreNotifierValue>();
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
