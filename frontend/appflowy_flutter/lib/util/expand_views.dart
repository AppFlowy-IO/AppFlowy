import 'package:flutter/cupertino.dart';

class ViewExpanderRegistry {
  /// the key is view id
  final Map<String, Set<ViewExpander>> _viewExpanders = {};

  bool isViewExpanded(String id) => getExpander(id)?.isViewExpanded ?? false;

  void register(String id, ViewExpander expander) {
    final expanders = _viewExpanders[id] ?? {};
    expanders.add(expander);
    _viewExpanders[id] = expanders;
  }

  void unregister(String id, ViewExpander expander) {
    final expanders = _viewExpanders[id] ?? {};
    expanders.remove(expander);
    if (expanders.isEmpty) {
      _viewExpanders.remove(id);
    } else {
      _viewExpanders[id] = expanders;
    }
  }

  ViewExpander? getExpander(String id) {
    final expanders = _viewExpanders[id] ?? {};
    return expanders.isEmpty ? null : expanders.first;
  }
}

class ViewExpander {
  ViewExpander(this._isExpandedCallback, this._expandCallback);

  final ValueGetter<bool> _isExpandedCallback;
  final VoidCallback _expandCallback;

  bool get isViewExpanded => _isExpandedCallback.call();

  void expand() => _expandCallback.call();
}
