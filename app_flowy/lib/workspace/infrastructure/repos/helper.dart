import 'dart:typed_data';
import 'package:flowy_sdk/protobuf/flowy-observable/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:dartz/dartz.dart';

class ObservableExtractor {
  String id;
  void Function(WorkspaceObservable, Either<Uint8List, WorkspaceError>)
      callback;

  ObservableExtractor({required this.id, required this.callback});

  void parse(ObservableSubject subject) {
    if (subject.id != id) {
      return;
    }

    final ty = WorkspaceObservable.valueOf(subject.ty);
    if (ty == null) {
      return;
    }

    if (subject.hasPayload()) {
      final bytes = Uint8List.fromList(subject.error);
      callback(ty, left(bytes));
    } else if (subject.hasError()) {
      final bytes = Uint8List.fromList(subject.error);
      final error = WorkspaceError.fromBuffer(bytes);
      callback(ty, right(error));
    } else {
      // do nothing
    }
  }
}
