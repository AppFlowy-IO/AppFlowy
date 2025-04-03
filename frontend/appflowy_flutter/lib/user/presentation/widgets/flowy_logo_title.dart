import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

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
    final theme = AppFlowyTheme.of(context);

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
          Text(
            title,
            style: theme.textStyle.heading.h3(
              color: theme.textColorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
