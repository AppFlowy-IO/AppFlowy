import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

class ViewService {
  Future<Either<ViewPB, FlowyError>> updateView({
    required final String viewId,
    final String? name,
    final String? desc,
  }) {
    final request = UpdateViewPayloadPB.create()..viewId = viewId;

    if (name != null) {
      request.name = name;
    }

    if (desc != null) {
      request.desc = desc;
    }

    return FolderEventUpdateView(request).send();
  }

  Future<Either<Unit, FlowyError>> delete({required final String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<Unit, FlowyError>> duplicate({required final ViewPB view}) {
    return FolderEventDuplicateView(view).send();
  }
}
