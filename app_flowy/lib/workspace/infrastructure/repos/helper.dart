import 'dart:typed_data';
import 'package:flowy_sdk/protobuf/flowy-observable/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:dartz/dartz.dart';

// class WorkspaceObservableParser {
//   String id;
//   void Function(WorkspaceObservable, Either<Uint8List, WorkspaceError>)
//       callback;

//   WorkspaceObservableParser({required this.id, required this.callback});
//   void parse(ObservableSubject subject) {
//     if (subject.id != id) {
//       return;
//     }

//     final ty = WorkspaceObservable.valueOf(subject.ty);
//     if (ty == null) {
//       return;
//     }

//     if (subject.hasPayload()) {
//       final bytes = Uint8List.fromList(subject.error);
//       callback(ty, left(bytes));
//     } else if (subject.hasError()) {
//       final bytes = Uint8List.fromList(subject.error);
//       final error = WorkspaceError.fromBuffer(bytes);
//       callback(ty, right(error));
//     } else {
//       // do nothing
//     }
//   }
// }

typedef UserObservableCallback = void Function(
    UserObservable, Either<Uint8List, UserError>);

class UserObservableParser extends ObservableParser<UserObservable, UserError> {
  UserObservableParser(
      {required String id, required UserObservableCallback callback})
      : super(
          id: id,
          callback: callback,
          tyParser: (ty) => UserObservable.valueOf(ty),
          errorParser: (bytes) => UserError.fromBuffer(bytes),
        );
}

typedef WorkspaceObservableCallback = void Function(
    WorkspaceObservable, Either<Uint8List, WorkspaceError>);

class WorkspaceObservableParser
    extends ObservableParser<WorkspaceObservable, WorkspaceError> {
  WorkspaceObservableParser(
      {required String id, required WorkspaceObservableCallback callback})
      : super(
          id: id,
          callback: callback,
          tyParser: (ty) => WorkspaceObservable.valueOf(ty),
          errorParser: (bytes) => WorkspaceError.fromBuffer(bytes),
        );
}

class ObservableParser<T, E> {
  String id;
  void Function(T, Either<Uint8List, E>) callback;

  T? Function(int) tyParser;
  E Function(Uint8List) errorParser;

  ObservableParser(
      {required this.id,
      required this.callback,
      required this.errorParser,
      required this.tyParser});
  void parse(ObservableSubject subject) {
    if (subject.id != id) {
      return;
    }

    final ty = tyParser(subject.ty);
    if (ty == null) {
      return;
    }

    if (subject.hasPayload()) {
      final bytes = Uint8List.fromList(subject.error);
      callback(ty, left(bytes));
    } else if (subject.hasError()) {
      final bytes = Uint8List.fromList(subject.error);
      final error = errorParser(bytes);
      callback(ty, right(error));
    } else {
      // do nothing
    }
  }
}
