import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:dartz/dartz.dart';

class OverviewAdapterBackendService {
  static Future<Either<Unit, FlowyError>> addListenerId(String viewId) {
    final payload = ViewIdPB.create()..value = viewId;
    return FolderEventRegisterOverviewListenerId(payload).send();
  }
}
