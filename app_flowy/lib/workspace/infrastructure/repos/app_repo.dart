import 'dart:async';
import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pbenum.dart';
import 'package:flowy_sdk/rust_stream.dart';

class AppRepository {
  String appId;
  AppRepository({
    required this.appId,
  });

  Future<Either<App, WorkspaceError>> getAppDesc() {
    final request = QueryAppRequest.create()
      ..appId = appId
      ..readBelongings = false;

    return WorkspaceEventReadApp(request).send();
  }

  Future<Either<View, WorkspaceError>> createView(
      String name, String desc, ViewType viewType) {
    final request = CreateViewRequest.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc
      ..viewType = viewType;

    return WorkspaceEventCreateView(request).send();
  }

  Future<Either<List<View>, WorkspaceError>> getViews() {
    final request = QueryAppRequest.create()
      ..appId = appId
      ..readBelongings = true;

    return WorkspaceEventReadApp(request).send().then((result) {
      return result.fold(
        (app) => left(app.belongings.items),
        (error) => right(error),
      );
    });
  }
}

class AppWatchRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  AppCreateViewCallback? _createView;
  AppDeleteViewCallback? _deleteView;
  AppUpdatedCallback? _update;
  String appId;
  late AppRepository _repo;
  AppWatchRepository({
    required this.appId,
  }) {
    _repo = AppRepository(appId: appId);
  }

  void startWatching(
      {AppCreateViewCallback? createView,
      AppDeleteViewCallback? deleteView,
      AppUpdatedCallback? update}) {
    _createView = createView;
    _deleteView = deleteView;
    _update = update;
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

  void _handleObservableType(WorkspaceObservable ty) {
    switch (ty) {
      case WorkspaceObservable.AppCreateView:
        if (_createView == null) {
          return;
        }
        _repo.getViews().then((result) {
          result.fold(
            (views) => _createView!(left(views)),
            (error) => _createView!(right(error)),
          );
        });
        break;
      case WorkspaceObservable.AppDeleteView:
        if (_deleteView == null) {
          return;
        }
        _repo.getViews().then((result) {
          result.fold(
            (views) => _deleteView!(left(views)),
            (error) => _deleteView!(right(error)),
          );
        });
        break;
      case WorkspaceObservable.AppUpdated:
        if (_update == null) {
          return;
        }
        _repo.getAppDesc().then((result) {
          result.fold(
            (app) => _update!(app.name, app.desc),
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
