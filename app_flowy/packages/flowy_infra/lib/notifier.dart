import 'package:flutter/material.dart';

class PublishNotifier<T> extends ChangeNotifier {
  T? _value;

  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }

  T? get currentValue => _value;

  void addPublishListener(void Function(T) callback) {
    super.addListener(() {
      if (_value != null) {
        callback(_value!);
      }
    });
  }
}
