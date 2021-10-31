import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_update.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:flowy_infra/notifier.dart';

import 'helper.dart';

class ViewRepository {
  View view;
  ViewRepository({
    required this.view,
  });

  Future<Either<View, WorkspaceError>> readView() {
    final request = QueryViewRequest(viewIds: [view.id]);
    return WorkspaceEventReadView(request).send();
  }

  Future<Either<View, WorkspaceError>> updateView({String? name, String? desc}) {
    final request = UpdateViewRequest.create()..viewId = view.id;

    if (name != null) {
      request.name = name;
    }

    if (desc != null) {
      request.desc = desc;
    }

    return WorkspaceEventUpdateView(request).send();
  }

  Future<Either<Unit, WorkspaceError>> delete() {
    final request = QueryViewRequest.create()..viewIds.add(view.id);
    return WorkspaceEventDeleteView(request).send();
  }

  Future<Either<Unit, WorkspaceError>> duplicate() {
    final request = QueryViewRequest.create()..viewIds.add(view.id);
    return WorkspaceEventDuplicateView(request).send();
  }
}

class ViewListenerRepository {
  StreamSubscription<SubscribeObject>? _subscription;
  PublishNotifier<UpdateNotifierValue> updatedNotifier = PublishNotifier<UpdateNotifierValue>();
  PublishNotifier<DeleteNotifierValue> deletedNotifier = PublishNotifier<DeleteNotifierValue>();
  PublishNotifier<RestoreNotifierValue> restoredNotifier = PublishNotifier<RestoreNotifierValue>();
  late WorkspaceNotificationParser _parser;
  View view;

  ViewListenerRepository({
    required this.view,
  });

  void start() {
    _parser = WorkspaceNotificationParser(
      id: view.id,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _handleObservableType(WorkspaceNotification ty, Either<Uint8List, WorkspaceError> result) {
    switch (ty) {
      case WorkspaceNotification.ViewUpdated:
        result.fold(
          (payload) => updatedNotifier.value = left(View.fromBuffer(payload)),
          (error) => updatedNotifier.value = right(error),
        );
        break;
      case WorkspaceNotification.ViewDeleted:
        result.fold(
          (payload) => deletedNotifier.value = left(View.fromBuffer(payload)),
          (error) => deletedNotifier.value = right(error),
        );
        break;
      case WorkspaceNotification.ViewRestored:
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
  }
}
