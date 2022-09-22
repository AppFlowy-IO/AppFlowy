import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

class ViewPluginNotifier extends PluginNotifier {
  final ViewListener? _viewListener;
  ViewPB view;

  @override
  final ValueNotifier<bool> isDeleted = ValueNotifier(false);

  @override
  final ValueNotifier<int> isDisplayChanged = ValueNotifier(0);

  ViewPluginNotifier({
    required this.view,
  }) : _viewListener = ViewListener(view: view) {
    _viewListener?.start(onViewUpdated: (result) {
      result.fold(
        (updatedView) {
          view = updatedView;
          isDisplayChanged.value = updatedView.hashCode;
        },
        (err) => Log.error(err),
      );
    }, onViewMoveToTrash: (result) {
      result.fold(
        (deletedView) {
          isDeleted.value = true;
        },
        (err) => Log.error(err),
      );
    });
  }

  @override
  void dispose() {
    isDeleted.dispose();
    isDisplayChanged.dispose();
    _viewListener?.stop();
  }
}
