import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

typedef SharedPages = List<SharedPage>;

class SharedPage {
  SharedPage({
    required this.view,
    required this.accessLevel,
  });

  final ViewPB view;
  final AFAccessLevelPB accessLevel;
}
