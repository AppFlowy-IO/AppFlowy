import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
class StyledProgressIndicator extends StatelessWidget {
  const StyledProgressIndicator({Key? key}) : super(key: key);

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
