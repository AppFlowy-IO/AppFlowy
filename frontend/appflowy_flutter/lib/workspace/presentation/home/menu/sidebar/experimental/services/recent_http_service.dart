import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class RecentHttpService {
  RecentHttpService({required this.workspaceId});

  final String workspaceId;

  /// Get the recent pages of the workspace.
  Future<FlowyResult<List<RecentFolderViewPB>, FlowyError>> getRecentPages() {
    final payload = GetRecentPagesPayloadPB.create()..workspaceId = workspaceId;

    return FolderEventGetRecentPages(payload).send().then((result) {
      return result.fold(
        (recentPages) => FlowySuccess(recentPages.items.toList()),
        (error) => FlowyFailure(error),
      );
    });
  }
}
