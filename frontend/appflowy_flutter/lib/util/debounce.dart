import 'dart:async';

import 'package:flutter/material.dart';

class Debounce {
  final Duration duration;
  Timer? _timer;

  Debounce({
    this.duration = const Duration(milliseconds: 1000),
  });

  void call(VoidCallback action) {
    dispose();
    _timer = Timer(duration, () {
      action();
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
