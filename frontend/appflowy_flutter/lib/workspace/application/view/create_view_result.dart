import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class CreatePageResult {

  CreatePageResult.succeed({
    this.createId,
    required this.layout,
  }) : succeed = true;

  CreatePageResult.failed({
    this.createId,
    required this.layout,
  }) : succeed = false;

  final String? createId;
  final ViewLayoutPB layout;
  final bool succeed;
}
