import 'package:appflowy/features/shared_sidebar/models/shared_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

extension RepeatedSharedViewResponsePBExtension
    on RepeatedSharedViewResponsePB {
  SharedPages get sharedPages {
    return sharedViews
        .map(
          (sharedView) => SharedPage(
            view: sharedView.view,
            accessLevel: sharedView.accessLevel,
          ),
        )
        .toList();
  }
}
