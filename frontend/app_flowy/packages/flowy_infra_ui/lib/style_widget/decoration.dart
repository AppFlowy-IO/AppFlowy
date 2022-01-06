import 'package:flutter/material.dart';

class FlowyDecoration {
  static Decoration decoration(
    Color boxColor,
    Color boxShadow, {
    double spreadRadius = 0,
    double blurRadius = 20,
    Offset offset = Offset.zero,
  }) {
    return BoxDecoration(
      color: boxColor,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
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
