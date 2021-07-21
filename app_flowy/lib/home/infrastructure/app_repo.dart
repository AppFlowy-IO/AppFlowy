import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';

class AppRepository {
  Future<Either<App, WorkspaceError>> createApp(String appName, String desc) {
    return WorkspaceEventGetCurWorkspace().send().then((result) {
      return result.fold(
        (workspace) {
          final request = CreateAppRequest.create()
            ..name = appName
            ..workspaceId = workspace.id
            ..desc = desc;
          return WorkspaceEventCreateApp(request).send();
        },
        (error) {
          return right(error);
        },
      );
    });
  }

  Future<Either<List<App>, WorkspaceError>> getApps(
      {required String workspaceId}) {
    final request = QueryWorkspaceRequest.create()
      ..workspaceId = workspaceId
      ..readApps = true;

    return WorkspaceEventGetWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace.apps.items),
        (error) => right(error),
      );
    });
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

  Future<Either<View, WorkspaceError>> createView(
      String appId, String name, String desc, ViewTypeIdentifier viewType) {
    final request = CreateViewRequest.create()
      ..appId = appId
      ..name = name
      ..desc = desc
      ..viewType = viewType;

    return WorkspaceEventCreateView(request).send();
  }
}
