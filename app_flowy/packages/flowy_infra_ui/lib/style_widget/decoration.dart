import 'package:flutter/material.dart';

class FlowyDecoration {
  static Decoration decoration() {
    return const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(6)),
      boxShadow: [
        BoxShadow(color: Color(0xfff2f2f2), spreadRadius: 1, blurRadius: 10.0),
      ],
    );
  }
}
