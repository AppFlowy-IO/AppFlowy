import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlowyLogoTitle extends StatelessWidget {
  const FlowyLogoTitle({
    super.key,
    required this.title,
    this.logoSize = const Size.square(40),
  });

  final String title;
  final Size logoSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.fromSize(
            size: logoSize,
            child: const FlowySvg(
              FlowySvgs.flowy_logo_xl,
              blendMode: null,
            ),
          ),
          const VSpace(20),
          FlowyText.regular(
            title,
            fontSize: FontSizes.s24,
            fontFamily:
                GoogleFonts.poppins(fontWeight: FontWeight.w500).fontFamily,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}
