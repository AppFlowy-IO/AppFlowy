import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class AppService {

  Future<Either<App, FlowyError>> getAppDesc({required String appId}) {
    final request = AppId.create()..value = appId;

    return FolderEventReadApp(request).send();
  }

  Future<Either<View, FlowyError>> createView({
    required String appId,
    required String name,
    required String desc,
    required ViewType viewType,
  }) {
    final request = CreateViewPayload.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc
      ..viewType = viewType;

    return FolderEventCreateView(request).send();
  }

  Future<Either<List<View>, FlowyError>> getViews({required String appId}) {
    final request = AppId.create()..value = appId;

    return FolderEventReadApp(request).send().then((result) {
      return result.fold(
        (app) => left(app.belongings.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> delete({required String appId}) {
    final request = AppId.create()..value = appId;
    return FolderEventDeleteApp(request).send();
  }

  Future<Either<Unit, FlowyError>> updateApp({required String appId, String? name}) {
    UpdateAppPayload request = UpdateAppPayload.create()..appId = appId;

    if (name != null) {
      request.name = name;
    }
    return FolderEventUpdateApp(request).send();
  }
}


