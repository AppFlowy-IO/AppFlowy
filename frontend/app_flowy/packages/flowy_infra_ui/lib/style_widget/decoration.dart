import 'package:flutter/material.dart';

class FlowyDecoration {
  static Decoration decoration(Color boxColor, Color boxShadow) {
    return BoxDecoration(
      color: boxColor,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      boxShadow: [
        BoxShadow(color: boxShadow, spreadRadius: 1, blurRadius: 10.0),
      ],
    );
  }
}
