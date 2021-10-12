import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:dartz/dartz.dart';

typedef ViewUpdatedCallback = void Function(Either<View, WorkspaceError>);

abstract class IView {
  View get view;

  Future<Either<Unit, WorkspaceError>> pushIntoTrash();

  Future<Either<Unit, WorkspaceError>> rename(String newName);
}

abstract class IViewListener {
  void start({ViewUpdatedCallback? updatedCallback});

  Future<void> stop();
}
