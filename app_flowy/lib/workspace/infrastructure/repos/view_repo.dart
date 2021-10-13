import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_delete.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_update.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

import 'package:app_flowy/workspace/domain/i_view.dart';

import 'helper.dart';

class ViewRepository {
  View view;
  ViewRepository({
    required this.view,
  });

  Future<Either<View, WorkspaceError>> readView() {
    final request = QueryViewRequest.create()..viewId = view.id;
    return WorkspaceEventReadView(request).send();
  }

  Future<Either<View, WorkspaceError>> updateView({String? name, String? desc, bool? isTrash}) {
    final request = UpdateViewRequest.create()..viewId = view.id;

    if (name != null) {
      request.name = name;
    }

    if (desc != null) {
      request.desc = desc;
    }

    if (isTrash != null) {
      request.isTrash = isTrash;
    }

    return WorkspaceEventUpdateView(request).send();
  }

  Future<Either<Unit, WorkspaceError>> delete() {
    final request = DeleteViewRequest.create()..viewId = view.id;
    return WorkspaceEventDeleteView(request).send();
  }
}

class ViewListenerRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  ViewUpdatedCallback? _update;
  late WorkspaceNotificationParser _extractor;
  View view;

  ViewListenerRepository({
    required this.view,
  });

  void startWatching({
    ViewUpdatedCallback? update,
  }) {
    _update = update;
    _extractor = WorkspaceNotificationParser(
      id: view.id,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _extractor.parse(observable));
  }

  void _handleObservableType(Notification ty, Either<Uint8List, WorkspaceError> result) {
    switch (ty) {
      case Notification.ViewUpdated:
        if (_update != null) {
          result.fold(
            (payload) {
              final view = View.fromBuffer(payload);
              _update!(left(view));
            },
            (error) => _update!(right(error)),
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}
