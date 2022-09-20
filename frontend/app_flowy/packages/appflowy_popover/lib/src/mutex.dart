import 'package:flutter/material.dart';

import 'popover.dart';

/// If multiple popovers are exclusive,
/// pass the same mutex to them.
class PopoverMutex {
  final ValueNotifier<PopoverState?> _stateNotifier = ValueNotifier(null);
  PopoverMutex();

  void removePopoverStateListener(VoidCallback listener) {
    _stateNotifier.removeListener(listener);
  }

  VoidCallback listenOnPopoverStateChanged(VoidCallback callback) {
    listenerCallback() {
      callback();
    }

    _stateNotifier.addListener(listenerCallback);
    return listenerCallback;
  }

  void close() {
    _stateNotifier.value?.close();
  }

  PopoverState? get state => _stateNotifier.value;

  set state(PopoverState? newState) {
    if (_stateNotifier.value != null && _stateNotifier.value != newState) {
      _stateNotifier.value?.close();
    }
    _stateNotifier.value = newState;
  }

  void removeState() {
    _stateNotifier.value = null;
  }

  void dispose() {
    _stateNotifier.dispose();
  }
}
