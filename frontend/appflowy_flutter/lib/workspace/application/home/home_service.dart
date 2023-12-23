import 'dart:async';

import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

class HomeService {
  Future<Either<ViewPB, FlowyError>> readApp({required String appId}) {
    final payload = ViewIdPB.create()..value = appId;

    return FolderEventGetView(payload).send();
  }
}
