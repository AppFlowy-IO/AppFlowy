import 'package:flowy_editor/flowy_editor.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class FlowyDoc {
  final Doc doc;
  final Document data;

  FlowyDoc({required this.doc, required this.data});
  String get id => doc.id;
}

abstract class IDoc {
  Future<Either<Doc, WorkspaceError>> readDoc();
  Future<Either<Unit, WorkspaceError>> saveDoc({String? text});
  Future<Either<Unit, WorkspaceError>> updateWithChangeset({String? text});
  Future<Either<Unit, WorkspaceError>> closeDoc();
}
