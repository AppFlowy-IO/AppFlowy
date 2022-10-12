import 'package:appflowy_board/src/utils/log.dart';

import 'phantom_controller.dart';
import 'package:flutter/material.dart';

class GroupPhantomState {
  final _groupStates = <String, GroupState>{};
  final _groupIsDragging = <String, bool>{};

  void setGroupIsDragging(String groupId, bool isDragging) {
    _groupIsDragging[groupId] = isDragging;
  }

  bool isDragging(String groupId) {
    return _groupIsDragging[groupId] ?? false;
  }

  void addGroupListener(String groupId, PassthroughPhantomListener listener) {
    if (_groupStates[groupId] == null) {
      Log.debug("[$GroupPhantomState] add group listener: $groupId");
      _groupStates[groupId] = GroupState();
      _groupStates[groupId]?.notifier.addListener(
            onInserted: (index) => listener.onInserted?.call(index),
            onDeleted: () => listener.onDragEnded?.call(),
          );
    }
  }

  void removeGroupListener(String groupId) {
    Log.debug("[$GroupPhantomState] remove group listener: $groupId");
    final groupState = _groupStates.remove(groupId);
    groupState?.dispose();
  }

  void notifyDidInsertPhantom(String groupId, int index) {
    _groupStates[groupId]?.notifier.insert(index);
  }

  void notifyDidRemovePhantom(String groupId) {
    Log.debug("[$GroupPhantomState] $groupId remove phantom");
    _groupStates[groupId]?.notifier.remove();
  }
}

class GroupState {
  bool isDragging = false;
  final notifier = PassthroughPhantomNotifier();

  void dispose() {
    notifier.dispose();
  }
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
