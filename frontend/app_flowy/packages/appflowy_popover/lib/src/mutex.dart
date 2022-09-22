import 'package:flutter/material.dart';

import 'popover.dart';

/// If multiple popovers are exclusive,
/// pass the same mutex to them.
class PopoverMutex {
  final _PopoverStateNotifier _stateNotifier = _PopoverStateNotifier();
  PopoverMutex();

  void removePopoverListener(VoidCallback listener) {
    _stateNotifier.removeListener(listener);
  }

  VoidCallback listenOnPopoverChanged(VoidCallback callback) {
    listenerCallback() {
      callback();
    }

    _stateNotifier.addListener(listenerCallback);
    return listenerCallback;
  }

  void close() => _stateNotifier.state?.close();

  PopoverState? get state => _stateNotifier.state;

  set state(PopoverState? newState) => _stateNotifier.state = newState;

  void removeState() {
    _stateNotifier.state = null;
  }

  void dispose() {
    _stateNotifier.dispose();
  }
}

class _PopoverStateNotifier extends ChangeNotifier {
  PopoverState? _state;

  PopoverState? get state => _state;

  set state(PopoverState? newState) {
    if (_state != null && _state != newState) {
      _state?.close();
    }
    _state = newState;
    notifyListeners();
  }
}
