import 'package:flutter/material.dart';

class CellDecoration {
  static BoxDecoration box({required Color color}) {
    return BoxDecoration(
      border: Border.all(color: Colors.black26, width: 0.2),
      color: color,
    );
  }
}
