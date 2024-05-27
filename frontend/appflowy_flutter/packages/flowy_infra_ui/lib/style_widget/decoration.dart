import 'package:flutter/material.dart';

class FlowyDecoration {
  static Decoration decoration(
    Color boxColor,
    Color boxShadow, {
    double spreadRadius = 0,
    double blurRadius = 20,
    Offset offset = Offset.zero,
    double borderRadius = 6,
  }) {
    return BoxDecoration(
      color: boxColor,
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      boxShadow: [
        BoxShadow(
          color: boxShadow,
          spreadRadius: spreadRadius,
          blurRadius: blurRadius,
          offset: offset,
        ),
      ],
    );
  }
}
