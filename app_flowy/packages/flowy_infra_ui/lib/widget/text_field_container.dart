import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TextFieldContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Size? size;
  const TextFieldContainer({
    Key? key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.borderColor = Colors.white,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = size == null ? 50 : size!.height;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: Colors.white,
        borderRadius: borderRadius,
      ),
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('child', child));
  }
}
