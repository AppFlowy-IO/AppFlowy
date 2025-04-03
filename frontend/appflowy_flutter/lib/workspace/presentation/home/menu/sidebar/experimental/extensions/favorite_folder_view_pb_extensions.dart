import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

extension FavoriteFolderViewPBX on FavoriteFolderViewPB {
  String get name => view.name;
  String get id => view.viewId;
}
