import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class ShareService {
  Future<Either<ExportData, FlowyError>> export(String docId, ExportType type) {
    final request = ExportPayload.create()
      ..docId = docId
      ..exportType = type;

    return FolderEventExportDocument(request).send();
  }

  Future<Either<ExportData, FlowyError>> exportText(String docId) {
    return export(docId, ExportType.Text);
  }

  Future<Either<ExportData, FlowyError>> exportMarkdown(String docId) {
    return export(docId, ExportType.Markdown);
  }

  Future<Either<ExportData, FlowyError>> exportURL(String docId) {
    return export(docId, ExportType.Link);
  }
}
