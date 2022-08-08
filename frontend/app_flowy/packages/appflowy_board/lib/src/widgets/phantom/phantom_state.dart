import 'phantom_controller.dart';
import 'package:flutter/material.dart';

class ColumnPhantomStateController {
  final _states = <String, ColumnState>{};

  void setColumnIsDragging(String columnId, bool isDragging) {
    _stateWithId(columnId).isDragging = isDragging;
  }

  bool isDragging(String columnId) {
    return _stateWithId(columnId).isDragging;
  }

  void addColumnListener(String columnId, PassthroughPhantomListener listener) {
    _stateWithId(columnId).notifier.addListener(
          onInserted: (c) => listener.onInserted?.call(),
          onDeleted: () => listener.onDragEnded?.call(),
        );
  }

  void removeColumnListener(String columnId) {
    _stateWithId(columnId).notifier.dispose();
    _states.remove(columnId);
  }

  void notifyDidInsertPhantom(String columnId) {
    _stateWithId(columnId).notifier.insert();
  }

  void notifyDidRemovePhantom(String columnId) {
    _stateWithId(columnId).notifier.remove();
  }

  ColumnState _stateWithId(String columnId) {
    var state = _states[columnId];
    if (state == null) {
      state = ColumnState();
      _states[columnId] = state;
    }
    return state;
  }
}

class ColumnState {
  bool isDragging = false;
  final notifier = PassthroughPhantomNotifier();
}

abstract class PassthroughPhantomListener {
  VoidCallback? get onInserted;
  VoidCallback? get onDragEnded;
}

class PassthroughPhantomNotifier {
  final insertNotifier = PhantomInsertNotifier();

  final removeNotifier = PhantomDeleteNotifier();

  void insert() {
    insertNotifier.insert();
  }

  void remove() {
    removeNotifier.remove();
  }

  void addListener({
    void Function(PassthroughPhantomContext? insertedPhantom)? onInserted,
    void Function()? onDeleted,
  }) {
    if (onInserted != null) {
      insertNotifier.addListener(() {
        onInserted(insertNotifier.insertedPhantom);
      });
    }

    if (onDeleted != null) {
      removeNotifier.addListener(() {
        onDeleted();
      });
    }
  }

  void dispose() {
    insertNotifier.dispose();
    removeNotifier.dispose();
  }
}

class PhantomInsertNotifier extends ChangeNotifier {
  PassthroughPhantomContext? insertedPhantom;

  void insert() {
    notifyListeners();
  }
}

class PhantomDeleteNotifier extends ChangeNotifier {
  void remove() {
    notifyListeners();
  }
}
