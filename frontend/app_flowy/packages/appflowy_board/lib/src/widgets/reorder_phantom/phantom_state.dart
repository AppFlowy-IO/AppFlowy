import 'phantom_controller.dart';
import 'package:flutter/material.dart';

class GroupPhantomState {
  final _states = <String, GroupState>{};

  void setGroupIsDragging(String groupId, bool isDragging) {
    _stateWithId(groupId).isDragging = isDragging;
  }

  bool isDragging(String groupId) {
    return _stateWithId(groupId).isDragging;
  }

  void addGroupListener(String groupId, PassthroughPhantomListener listener) {
    _stateWithId(groupId).notifier.addListener(
          onInserted: (index) => listener.onInserted?.call(index),
          onDeleted: () => listener.onDragEnded?.call(),
        );
  }

  void removeGroupListener(String groupId) {
    _stateWithId(groupId).notifier.dispose();
    _states.remove(groupId);
  }

  void notifyDidInsertPhantom(String groupId, int index) {
    _stateWithId(groupId).notifier.insert(index);
  }

  void notifyDidRemovePhantom(String groupId) {
    _stateWithId(groupId).notifier.remove();
  }

  GroupState _stateWithId(String groupId) {
    var state = _states[groupId];
    if (state == null) {
      state = GroupState();
      _states[groupId] = state;
    }
    return state;
  }
}

class GroupState {
  bool isDragging = false;
  final notifier = PassthroughPhantomNotifier();
}

abstract class PassthroughPhantomListener {
  void Function(int?)? get onInserted;
  VoidCallback? get onDragEnded;
}

class PassthroughPhantomNotifier {
  final insertNotifier = PhantomInsertNotifier();

  final removeNotifier = PhantomDeleteNotifier();

  void insert(int index) {
    insertNotifier.insert(index);
  }

  void remove() {
    removeNotifier.remove();
  }

  void addListener({
    void Function(int? insertedIndex)? onInserted,
    void Function()? onDeleted,
  }) {
    if (onInserted != null) {
      insertNotifier.addListener(() {
        onInserted(insertNotifier.insertedIndex);
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
  int insertedIndex = -1;
  PassthroughPhantomContext? insertedPhantom;

  void insert(int index) {
    insertedIndex = index;
    notifyListeners();
  }
}

class PhantomDeleteNotifier extends ChangeNotifier {
  void remove() {
    notifyListeners();
  }
}
