import 'package:flutter/material.dart';

extension ThemeExtension on ThemeData {
  T? extensionOrNull<T>() {
    if (extensions.containsKey(T)) {
      return extensions[T] as T;
    }
    return null;
  }
}
