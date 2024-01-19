import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:dartz/dartz.dart';

class OverviewAdapterBackendService {
  /// Registers an overview block listener Id in the backend, allowing us to receive
  /// notifications of [FolderNotification.DidUpdateWorkspaceOverviewChildViews] from
  /// all levels of child views to the specified parent view Id listener.
  static Future<Either<Unit, FlowyError>> addListenerId(String viewId) {
    final payload = ViewIdPB.create()..value = viewId;
    return FolderEventRegisterOverviewListenerId(payload).send();
  }
}
