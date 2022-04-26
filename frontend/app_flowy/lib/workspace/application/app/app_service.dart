import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';

import 'package:app_flowy/plugin/plugin.dart';

class AppService {
  final String appId;
  AppService({
    required this.appId,
  });

  Future<Either<App, FlowyError>> getAppDesc({required String appId}) {
    final payload = AppId.create()..value = appId;

    return FolderEventReadApp(payload).send();
  }

  Future<Either<View, FlowyError>> createView({
    required String appId,
    required String name,
    required String desc,
    required PluginDataType dataType,
    required PluginType pluginType,
  }) {
    final payload = CreateViewPayload.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc
      ..dataType = dataType
      ..pluginType = pluginType;

    return FolderEventCreateView(payload).send();
  }

  Future<Either<List<View>, FlowyError>> getViews({required String appId}) {
    final payload = AppId.create()..value = appId;

    return FolderEventReadApp(payload).send().then((result) {
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
    UpdateAppPayload payload = UpdateAppPayload.create()..appId = appId;

    if (name != null) {
      payload.name = name;
    }
    return FolderEventUpdateApp(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveView({
    required String viewId,
    required int fromIndex,
    required int toIndex,
  }) {
    final payload = MoveFolderItemPayload.create()
      ..itemId = viewId
      ..from = fromIndex
      ..to = toIndex
      ..ty = MoveFolderItemType.MoveView;

    return FolderEventMoveItem(payload).send();
  }
}
