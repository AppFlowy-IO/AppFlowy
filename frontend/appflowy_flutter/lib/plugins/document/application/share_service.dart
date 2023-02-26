import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class ShareService {
  Future<Either<ExportDataPB, FlowyError>> export(
      ViewPB view, ExportType type) {
    var payload = ExportPayloadPB.create()
      ..viewId = view.id
      ..exportType = type
      ..documentVersion = DocumentVersionPB.V1;

    return DocumentEventExportDocument(payload).send();
  }

  Future<Either<ExportDataPB, FlowyError>> exportText(ViewPB view) {
    return export(view, ExportType.Text);
  }

  Future<Either<ExportDataPB, FlowyError>> exportMarkdown(ViewPB view) {
    return export(view, ExportType.Markdown);
  }

  Future<Either<ExportDataPB, FlowyError>> exportURL(ViewPB view) {
    return export(view, ExportType.Link);
  }
}
