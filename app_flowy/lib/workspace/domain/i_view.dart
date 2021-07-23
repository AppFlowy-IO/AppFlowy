import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';

typedef ViewUpdatedCallback = void Function(View view);

abstract class IViewWatch {
  void startWatching({ViewUpdatedCallback? updatedCallback});

  Future<void> stopWatching();
}
