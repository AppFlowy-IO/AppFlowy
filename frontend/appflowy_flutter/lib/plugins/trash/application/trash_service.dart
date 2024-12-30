import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class TrashService {
  Future<FlowyResult<RepeatedTrashPB, FlowyError>> readTrash() {
    return FolderEventListTrashItems().send();
  }

  static Future<FlowyResult<void, FlowyError>> putback(String trashId) {
    final id = TrashIdPB.create()..id = trashId;

    return FolderEventRestoreTrashItem(id).send();
  }

  Future<FlowyResult<void, FlowyError>> deleteViews(List<String> trash) {
    final items = trash.map((trash) {
      return TrashIdPB.create()..id = trash;
    });

    final ids = RepeatedTrashIdPB(items: items);
    return FolderEventPermanentlyDeleteTrashItem(ids).send();
  }

  Future<FlowyResult<void, FlowyError>> restoreAll() {
    return FolderEventRecoverAllTrashItems().send();
  }

  Future<FlowyResult<void, FlowyError>> deleteAll() {
    return FolderEventPermanentlyDeleteAllTrashItem().send();
  }
}
