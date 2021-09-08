import 'dart:async';
import 'dart:typed_data';

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
}

class ViewWatchRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  ViewUpdatedCallback? _update;
  late WorkspaceObservableParser _extractor;
  View view;

  ViewWatchRepository({
    required this.view,
  });

  void startWatching({
    ViewUpdatedCallback? update,
  }) {
    _update = update;
    _extractor = WorkspaceObservableParser(
      id: view.id,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription =
        RustStreamReceiver.listen((observable) => _extractor.parse(observable));
  }

  void _handleObservableType(
      WorkspaceObservable ty, Either<Uint8List, WorkspaceError> result) {
    switch (ty) {
      case WorkspaceObservable.ViewUpdated:
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
