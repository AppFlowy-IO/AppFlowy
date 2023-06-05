import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

class ViewPluginNotifier extends PluginNotifier<Option<DeletedViewPB>> {
  final ViewListener? _viewListener;
  ViewPB view;

  @override
  final ValueNotifier<Option<DeletedViewPB>> isDeleted = ValueNotifier(none());

  @override
  final ValueNotifier<int> isDisplayChanged = ValueNotifier(0);

  ViewPluginNotifier({
    required this.view,
  }) : _viewListener = ViewListener(view: view) {
    _viewListener?.start(
      onViewUpdated: (final result) {
        result.fold(
          (final updatedView) {
            view = updatedView;
            isDisplayChanged.value = updatedView.hashCode;
          },
          (final err) => Log.error(err),
        );
      },
      onViewMoveToTrash: (final result) {
        result.fold(
          (final deletedView) => isDeleted.value = some(deletedView),
          (final err) => Log.error(err),
        );
      },
    );
  }

  @override
  void dispose() {
    isDeleted.dispose();
    isDisplayChanged.dispose();
    _viewListener?.stop();
  }
}
