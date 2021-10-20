import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:dartz/dartz.dart';

typedef ViewUpdatedCallback = void Function(Either<View, WorkspaceError>);

abstract class IView {
  View get view;

  Future<Either<Unit, WorkspaceError>> delete();

  Future<Either<View, WorkspaceError>> rename(String newName);

  Future<Either<Unit, WorkspaceError>> duplicate();
}

abstract class IViewListener {
  void start({ViewUpdatedCallback? updatedCallback});

  Future<void> stop();
}
