import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class ShareRepo {
  Future<Either<ExportData, WorkspaceError>> export(String docId, ExportType type) {
    final request = ExportRequest.create()
      ..docId = docId
      ..exportType = type;

    return WorkspaceEventExportDocument(request).send();
  }
}
