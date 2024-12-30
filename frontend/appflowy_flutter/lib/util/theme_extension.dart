import 'package:flutter/material.dart';

extension IsLightMode on ThemeData {
  bool get isLightMode => brightness == Brightness.light;
}
