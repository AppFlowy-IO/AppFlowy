import 'package:flutter/material.dart';

class FlowyDecoration {
  static Decoration decoration(Color theme_color, Color box_shadow) {
    return BoxDecoration(
      color: theme_color,
      borderRadius: BorderRadius.all(Radius.circular(6)),
      boxShadow: [
        BoxShadow(color: box_shadow, spreadRadius: 1, blurRadius: 10.0),
      ],
    );
  }
}
