import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

import 'package:app_flowy/startup/plugin/plugin.dart';

class AppService {
  Future<Either<AppPB, FlowyError>> readApp({required String appId}) {
    final payload = AppIdPB.create()..value = appId;

    return FolderEventReadApp(payload).send();
  }

  Future<Either<ViewPB, FlowyError>> createView({
    required String appId,
    required String name,
    String? desc,
    required ViewDataFormatPB dataFormatType,
    required PluginType pluginType,
    required ViewLayoutTypePB layoutType,
  }) {
    var payload = CreateViewPayloadPB.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc ?? ""
      ..dataFormat = dataFormatType
      ..layout = layoutType;

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

  Future<Either<Unit, FlowyError>> deleteView({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
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
