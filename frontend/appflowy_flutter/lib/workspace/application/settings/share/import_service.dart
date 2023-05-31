import 'dart:convert';
import 'dart:typed_data';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/import.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';
import 'package:dartz/dartz.dart';

class ImportBackendService {
  static Future<Either<Unit, FlowyError>> importHistoryDatabase(
    String data,
    String name,
    String parentViewId,
  ) async {
    final payload = ImportPB.create()
      ..data = utf8.encode(data)
      ..parentViewId = parentViewId
      ..viewLayout = ViewLayoutPB.Grid
      ..name = name
      ..importType = ImportTypePB.HistoryDatabase;

    return await FolderEventImportData(payload).send();
  }

  static Future<Either<Unit, FlowyError>> importHistoryDocument(
    Uint8List data,
    String name,
    String parentViewId,
  ) async {
    final payload = ImportPB.create()
      ..data = data
      ..parentViewId = parentViewId
      ..viewLayout = ViewLayoutPB.Document
      ..name = name
      ..importType = ImportTypePB.HistoryDocument;

    return await FolderEventImportData(payload).send();
  }
}
