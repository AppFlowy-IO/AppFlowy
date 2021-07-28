import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

import 'package:app_flowy/workspace/domain/i_view.dart';

class ViewRepository {
  View view;
  ViewRepository({
    required this.view,
  });

  Future<Either<View, WorkspaceError>> readView() {
    final request = QueryViewRequest.create()..viewId = view.id;
    return WorkspaceEventReadView(request).send();
  }
}

class ViewWatchRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  ViewUpdatedCallback? _updatedCallback;
  View view;
  late ViewRepository _repo;
  ViewWatchRepository({
    required this.view,
  }) {
    _repo = ViewRepository(view: view);
  }

  void startWatching({
    ViewUpdatedCallback? updatedCallback,
  }) {
    _updatedCallback = updatedCallback;
    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.subjectId != view.id) {
        return;
      }

      final ty = WorkspaceObservable.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty);
      }
    });
  }

  void _handleObservableType(WorkspaceObservable ty) {
    switch (ty) {
      case WorkspaceObservable.ViewUpdateDesc:
        if (_updatedCallback == null) {
          return;
        }
        _repo.readView().then((result) {
          result.fold(
            (view) => _updatedCallback!(view),
            (error) => Log.error(error),
          );
        });
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}
