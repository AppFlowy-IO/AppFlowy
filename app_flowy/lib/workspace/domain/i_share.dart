import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

abstract class IShare {
  Future<Either<ExportData, WorkspaceError>> exportText(String docId);

  Future<Either<ExportData, WorkspaceError>> exportMarkdown(String docId);

  Future<Either<ExportData, WorkspaceError>> exportURL(String docId);
}
