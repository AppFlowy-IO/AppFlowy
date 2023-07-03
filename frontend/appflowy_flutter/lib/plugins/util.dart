import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class ViewPluginNotifier extends PluginNotifier<Option<DeletedViewPB>> {
  final ViewListener? _viewListener;
  ViewPB view;

  @override
  final ValueNotifier<Option<DeletedViewPB>> isDeleted = ValueNotifier(none());

  ViewPluginNotifier({
    required this.view,
  }) : _viewListener = ViewListener(viewId: view.id) {
    _viewListener?.start(
      onViewUpdated: (updatedView) {
        view = updatedView;
      },
      onViewMoveToTrash: (result) {
        result.fold(
          (deletedView) => isDeleted.value = some(deletedView),
          (err) => Log.error(err),
        );
      },
    );
  }

  @override
  void dispose() {
    isDeleted.dispose();
    _viewListener?.stop();
  }
}
