import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class MenuSharedState {
  final ValueNotifier<ViewPB?> _latestOpenView = ValueNotifier<ViewPB?>(null);

  MenuSharedState({ViewPB? view}) {
    _latestOpenView.value = view;
  }

  ViewPB? get latestOpenView => _latestOpenView.value;
  ValueNotifier<ViewPB?> get notifier => _latestOpenView;

  set latestOpenView(ViewPB? view) {
    if (_latestOpenView.value?.id != view?.id) {
      _latestOpenView.value = view;
    }
  }

  VoidCallback addLatestViewListener(void Function(ViewPB?) callback) {
    listener() {
      callback(_latestOpenView.value);
    }

    _latestOpenView.addListener(listener);
    return listener;
  }

  void removeLatestViewListener(VoidCallback listener) {
    _latestOpenView.removeListener(listener);
  }
}
