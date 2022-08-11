import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-text-block/protobuf.dart';

class ShareService {
  Future<Either<ExportDataPB, FlowyError>> export(String docId, ExportType type) {
    final request = ExportPayloadPB.create()
      ..viewId = docId
      ..exportType = type;

    return TextBlockEventExportDocument(request).send();
  }

  Future<Either<ExportDataPB, FlowyError>> exportText(String docId) {
    return export(docId, ExportType.Text);
  }

  Future<Either<ExportDataPB, FlowyError>> exportMarkdown(String docId) {
    return export(docId, ExportType.Markdown);
  }

  Future<Either<ExportDataPB, FlowyError>> exportURL(String docId) {
    return export(docId, ExportType.Link);
  }
}
