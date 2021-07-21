import 'dart:async';
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

typedef AppUpdatedCallback = void Function(String name, String desc);
typedef ViewUpdatedCallback = void Function(List<View> views);

class AppRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  ViewUpdatedCallback? _viewUpdatedCallback;
  AppUpdatedCallback? _appUpdatedCallback;
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
      String appId, String name, String desc, ViewTypeIdentifier viewType) {
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
      {ViewUpdatedCallback? viewUpdatedCallback,
      AppUpdatedCallback? appUpdatedCallback}) {
    _viewUpdatedCallback = viewUpdatedCallback;
    _appUpdatedCallback = appUpdatedCallback;
    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.subjectId != appId) {
        return;
      }

      final ty = WorkspaceObservableType.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty);
      }
    });
  }

  void _handleObservableType(WorkspaceObservableType ty) {
    switch (ty) {
      case WorkspaceObservableType.ViewUpdated:
        if (_viewUpdatedCallback == null) {
          return;
        }
        getViews(appId: appId).then((result) {
          result.fold(
            (views) => _viewUpdatedCallback!(views),
            (error) => Log.error(error),
          );
        });
        break;
      case WorkspaceObservableType.AppDescUpdated:
        if (_appUpdatedCallback == null) {
          return;
        }
        getAppDesc().then((result) {
          result.fold(
            (app) => _appUpdatedCallback!(app.name, app.desc),
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
