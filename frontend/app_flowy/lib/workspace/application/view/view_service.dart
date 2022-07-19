import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class ViewService {
  Future<Either<ViewPB, FlowyError>> readView({required String viewId}) {
    final request = ViewIdPB(value: viewId);
    return FolderEventReadView(request).send();
  }

  Future<Either<ViewPB, FlowyError>> updateView({required String viewId, String? name, String? desc}) {
    final request = UpdateViewPayloadPB.create()..viewId = viewId;

    if (name != null) {
      request.name = name;
    }

    if (desc != null) {
      request.desc = desc;
    }

    return FolderEventUpdateView(request).send();
  }

  Future<Either<Unit, FlowyError>> delete({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<Unit, FlowyError>> duplicate({required String viewId}) {
    final request = ViewIdPB(value: viewId);
    return FolderEventDuplicateView(request).send();
  }
}
