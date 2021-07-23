import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';

class ViewWatchRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  ViewUpdatedCallback? _updatedCallback;
  String viewId;
  ViewWatchRepository({
    required this.viewId,
  });

  void startWatching({
    ViewUpdatedCallback? updatedCallback,
  }) {
    _addViewCallback = addViewCallback;
    _updatedCallback = updatedCallback;
    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.subjectId != appId) {
        return;
      }

      final ty = WorkspaceObservable.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty);
      }
    });
  }
}
