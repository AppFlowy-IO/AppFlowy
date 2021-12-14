import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

abstract class IShare {
  Future<Either<ExportData, FlowyError>> exportText(String docId);

  Future<Either<ExportData, FlowyError>> exportMarkdown(String docId);

  Future<Either<ExportData, FlowyError>> exportURL(String docId);
}
