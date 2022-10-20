import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-document/entities.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-document/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';

class ShareService {
  Future<Either<ExportDataPB, FlowyError>> export(
      ViewPB view, ExportType type) {
    var payload = ExportPayloadPB.create()
      ..viewId = view.id
      ..exportType = type;

    switch (view.dataType) {
      case ViewDataFormatPB.DeltaFormat:
        payload.documentType = DocumentTypePB.Delta;
        break;
      default:
        payload.documentType = DocumentTypePB.NodeTree;
        break;
    }

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
