import 'package:flutter/material.dart';

abstract class Comparable<T> {
  bool compare(T? previous, T? current);
}

class ObjectComparable<T> extends Comparable<T> {
  @override
  bool compare(T? previous, T? current) {
    return previous == current;
  }
}

class PublishNotifier<T> extends ChangeNotifier {
  T? _value;
  Comparable<T>? comparable = ObjectComparable();

  PublishNotifier({this.comparable});

  set value(T newValue) {
    if (comparable != null) {
      if (comparable!.compare(_value, newValue)) {
        _value = newValue;
        notifyListeners();
      }
    } else {
      _value = newValue;
      notifyListeners();
    }
  }

  T? get currentValue => _value;

  void addPublishListener(void Function(T) callback) {
    super.addListener(
      () {
        if (_value != null) {
          callback(_value!);
        }
      },
    );
  }
}
