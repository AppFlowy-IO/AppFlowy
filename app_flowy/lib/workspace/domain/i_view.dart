import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:dartz/dartz.dart';

typedef ViewUpdatedCallback = void Function(Either<View, WorkspaceError>);

abstract class IView {
  Future<Either<View, WorkspaceError>> readView();
}

abstract class IViewWatch {
  void startWatching({ViewUpdatedCallback? updatedCallback});

  Future<void> stopWatching();
}
