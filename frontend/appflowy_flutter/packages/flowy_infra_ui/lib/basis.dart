import 'package:flutter/material.dart';

// MARK: - Shared Builder

typedef WidgetBuilder = Widget Function();

typedef IndexedCallback = void Function(int index);
typedef IndexedValueCallback<T> = void Function(T value, int index);
