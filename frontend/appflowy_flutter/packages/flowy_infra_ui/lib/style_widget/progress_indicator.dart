import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

List<Color> _kDefaultRainbowColors = const [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
];

// CircularProgressIndicator()
class FlowyProgressIndicator extends StatelessWidget {
  const FlowyProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: SizedBox(
          width: 60,
          child: LoadingIndicator(
            indicatorType: Indicator.pacman,
            colors: _kDefaultRainbowColors,
            strokeWidth: 4.0,
          ),
        ),
      ),
    );
  }
}
