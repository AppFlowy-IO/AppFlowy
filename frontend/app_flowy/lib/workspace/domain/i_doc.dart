import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-document-infra/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';

abstract class IDoc {
  Future<Either<DocDelta, WorkspaceError>> readDoc();
  Future<Either<DocDelta, WorkspaceError>> composeDelta({required String json});
  Future<Either<Unit, WorkspaceError>> closeDoc();
}
