import 'dart:async';
import 'package:app_flowy/home/domain/i_app.dart';
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
  StreamSubscription<ObservableSubject>? _subscription;
  AppAddViewCallback? _addViewCallback;
  AppUpdatedCallback? _updatedCallback;
  String appId;
  AppRepository({
    required this.appId,
  });

  Future<Either<App, WorkspaceError>> getAppDesc() {
    final request = QueryAppRequest.create()
      ..appId = appId
      ..readViews = false;

    return WorkspaceEventGetApp(request).send();
  }

  Future<Either<View, WorkspaceError>> createView(
      String appId, String name, String desc, ViewType viewType) {
    final request = CreateViewRequest.create()
      ..appId = appId
      ..name = name
      ..desc = desc
      ..viewType = viewType;

    return WorkspaceEventCreateView(request).send();
  }

  Future<Either<List<View>, WorkspaceError>> getViews({required String appId}) {
    final request = QueryAppRequest.create()
      ..appId = appId
      ..readViews = true;

    return WorkspaceEventGetApp(request).send().then((result) {
      return result.fold(
        (app) => left(app.views.items),
        (error) => right(error),
      );
    });
  }

  void startWatching(
      {AppAddViewCallback? addViewCallback,
      AppUpdatedCallback? updatedCallback}) {
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

  void _handleObservableType(WorkspaceObservable ty) {
    switch (ty) {
      case WorkspaceObservable.AppAddView:
        if (_addViewCallback == null) {
          return;
        }
        getViews(appId: appId).then((result) {
          result.fold(
            (views) => _addViewCallback!(left(views)),
            (error) => _addViewCallback!(right(error)),
          );
        });
        break;
      case WorkspaceObservable.AppUpdateDesc:
        if (_updatedCallback == null) {
          return;
        }
        getAppDesc().then((result) {
          result.fold(
            (app) => _updatedCallback!(app.name, app.desc),
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
