import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/doc_create.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/errors.pb.dart';

class Doc {
  final DocInfo info;
  final Document data;

  Doc({required this.info, required this.data});
}

abstract class IDoc {
  Future<Either<Doc, EditorError>> readDoc();
  Future<Either<Unit, EditorError>> updateDoc(
      {String? name, String? desc, String? text});
  Future<Either<Unit, EditorError>> closeDoc();
}
