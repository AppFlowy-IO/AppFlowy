import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef SectionNotifyValue = FlowyResult<SectionViewsPB, FlowyError>;

/// The [WorkspaceSectionsListener] listens to the changes including the below:
///
/// - The root views inside different section of the workspace. (Not including the views are inside the root views)
///   depends on the section type(s).
class WorkspaceSectionsListener {
  WorkspaceSectionsListener({
    required this.user,
    required this.workspaceId,
  });

  final UserProfilePB user;
  final String workspaceId;

  final _sectionNotifier = PublishNotifier<SectionNotifyValue>();
  late final FolderNotificationListener _listener;

  void start({
    void Function(SectionNotifyValue)? sectionChanged,
  }) {
    if (sectionChanged != null) {
      _sectionNotifier.addPublishListener(sectionChanged);
    }

    _listener = FolderNotificationListener(
      objectId: workspaceId,
      handler: _handleObservableType,
    );
  }

  void _handleObservableType(
    FolderNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateSectionViews:
        final FlowyResult<SectionViewsPB, FlowyError> value = result.fold(
          (s) => FlowyResult.success(
            SectionViewsPB.fromBuffer(s),
          ),
          (f) => FlowyResult.failure(f),
        );
        _sectionNotifier.value = value;
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _sectionNotifier.dispose();

    await _listener.stop();
  }
}
