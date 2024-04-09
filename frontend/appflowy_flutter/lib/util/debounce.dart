import 'dart:async';

class Debounce {
  Debounce({
    this.duration = const Duration(milliseconds: 1000),
  });

  final Duration duration;
  Timer? _timer;

  void call(Function action) {
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
