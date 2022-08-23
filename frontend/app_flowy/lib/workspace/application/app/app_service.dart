import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';

import 'package:app_flowy/startup/plugin/plugin.dart';

class AppService {
  final String appId;
  AppService({
    required this.appId,
  });

  Future<Either<AppPB, FlowyError>> getAppDesc({required String appId}) {
    final payload = AppIdPB.create()..value = appId;

    return FolderEventReadApp(payload).send();
  }

  Future<Either<ViewPB, FlowyError>> createView({
    required String appId,
    required String name,
    required String desc,
    required ViewDataTypePB dataType,
    required PluginType pluginType,
    required ViewLayoutTypePB layout,
  }) {
    var payload = CreateViewPayloadPB.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc
      ..dataType = dataType
      ..layout = layout;

    return FolderEventCreateView(payload).send();
  }

  Future<Either<List<ViewPB>, FlowyError>> getViews({required String appId}) {
    final payload = AppIdPB.create()..value = appId;

    return FolderEventReadApp(payload).send().then((result) {
      return result.fold(
        (app) => left(app.belongings.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> delete({required String appId}) {
    final request = AppIdPB.create()..value = appId;
    return FolderEventDeleteApp(request).send();
  }

  Future<Either<Unit, FlowyError>> updateApp(
      {required String appId, String? name}) {
    UpdateAppPayloadPB payload = UpdateAppPayloadPB.create()..appId = appId;

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
    final payload = MoveFolderItemPayloadPB.create()
      ..itemId = viewId
      ..from = fromIndex
      ..to = toIndex
      ..ty = MoveFolderItemType.MoveView;

    return FolderEventMoveFolderItem(payload).send();
  }
}
