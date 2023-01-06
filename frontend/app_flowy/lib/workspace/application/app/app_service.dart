import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';

import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';

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

  Future<List<Tuple2<AppPB, List<ViewPB>>>> fetchViews(
      ViewLayoutTypePB layoutType) async {
    final result = <Tuple2<AppPB, List<ViewPB>>>[];
    return FolderEventReadCurrentWorkspace().send().then((value) async {
      final workspaces = value.getLeftOrNull<WorkspaceSettingPB>();
      if (workspaces != null) {
        final apps = workspaces.workspace.apps.items;
        for (var app in apps) {
          final views = await getViews(appId: app.id).then(
            (value) => value
                .getLeftOrNull<List<ViewPB>>()
                ?.where((e) => e.layout == layoutType)
                .toList(),
          );
          if (views != null && views.isNotEmpty) {
            result.add(Tuple2(app, views));
          }
        }
      }
      return result;
    });
  }

  Future<Either<ViewPB, FlowyError>> getView(
    String appID,
    String viewID,
  ) async {
    final payload = AppIdPB.create()..value = appID;
    return FolderEventReadApp(payload).send().then((result) {
      return result.fold(
        (app) => left(
          app.belongings.items.firstWhere((e) => e.id == viewID),
        ),
        (error) => right(error),
      );
    });
  }
}

extension AppFlowy on Either {
  T? getLeftOrNull<T>() {
    if (isLeft()) {
      final result = fold<T?>((l) => l, (r) => null);
      return result;
    }
    return null;
  }
}
