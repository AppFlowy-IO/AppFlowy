import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class ShareRepo {
  Future<Either<ExportData, FlowyError>> export(String docId, ExportType type) {
    final request = ExportRequest.create()
      ..docId = docId
      ..exportType = type;

    return WorkspaceEventExportDocument(request).send();
  }
}
