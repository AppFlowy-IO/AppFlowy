import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart';

class DatabaseLayoutBackendService {
  final String viewId;

  DatabaseLayoutBackendService(this.viewId);

  Future<Either<ViewPB, FlowyError>> updateLayout({
    required String fieldId,
    required DatabaseLayoutPB layout,
  }) {
    final payload = UpdateViewPayloadPB.create()
      ..viewId = viewId
      ..layout = _viewLayoutFromDatabaseLayout(layout);

    return FolderEventUpdateView(payload).send();
  }
}

ViewLayoutPB _viewLayoutFromDatabaseLayout(DatabaseLayoutPB databaseLayout) {
  switch (databaseLayout) {
    case DatabaseLayoutPB.Board:
      return ViewLayoutPB.Board;
    case DatabaseLayoutPB.Calendar:
      return ViewLayoutPB.Calendar;
    case DatabaseLayoutPB.Grid:
      return ViewLayoutPB.Grid;
    default:
      throw UnimplementedError;
  }
}
