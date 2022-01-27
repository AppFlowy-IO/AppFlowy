import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

abstract class IShare {
  Future<Either<ExportData, FlowyError>> exportText(String docId);

  Future<Either<ExportData, FlowyError>> exportMarkdown(String docId);

  Future<Either<ExportData, FlowyError>> exportURL(String docId);
}
