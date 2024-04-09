import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class HomeService {
  static Future<FlowyResult<ViewPB, FlowyError>> readApp({
    required String appId,
  }) {
    final payload = ViewIdPB.create()..value = appId;
    return FolderEventGetView(payload).send();
  }
}
