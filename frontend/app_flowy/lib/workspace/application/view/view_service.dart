import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class ViewService {
  Future<Either<View, FlowyError>> readView({required String viewId}) {
    final request = ViewId(value: viewId);
    return FolderEventReadView(request).send();
  }

  Future<Either<View, FlowyError>> updateView({required String viewId, String? name, String? desc}) {
    final request = UpdateViewPayload.create()..viewId = viewId;

    if (name != null) {
      request.name = name;
    }

    if (desc != null) {
      request.desc = desc;
    }

    return FolderEventUpdateView(request).send();
  }

  Future<Either<Unit, FlowyError>> delete({required String viewId}) {
    final request = RepeatedViewId.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<Unit, FlowyError>> duplicate({required String viewId}) {
    final request = ViewId(value: viewId);
    return FolderEventDuplicateView(request).send();
  }
}
