import 'package:flutter/widgets.dart';

class EditorDropManagerState extends ChangeNotifier {
  final Set<String> _draggedTypes = {};

  void add(String type) {
    _draggedTypes.add(type);
    notifyListeners();
  }

  void remove(String type) {
    _draggedTypes.remove(type);
    notifyListeners();
  }

  bool get isDropEnabled => _draggedTypes.isEmpty;
}
