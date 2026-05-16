import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';

class AFLogo extends StatelessWidget {
  const AFLogo({
    super.key,
    this.size = const Size.square(36),
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return FlowySvg(
      FlowySvgs.app_logo_xl,
      blendMode: null,
      size: size,
    );
  }
}
