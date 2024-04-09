import 'dart:async';

class Throttler {
  Throttler({
    this.duration = const Duration(milliseconds: 1000),
  });

  final Duration duration;
  Timer? _timer;

  void call(Function callback) {
    if (_timer?.isActive ?? false) return;

    _timer = Timer(duration, () {
      callback();
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
