import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(16));

class CustomScrollToBottom extends StatelessWidget {
  const CustomScrollToBottom({
    super.key,
    required this.animation,
    required this.onPressed,
  });

  final Animation<double> animation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: ScaleTransition(
          scale: animation,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              borderRadius: _borderRadius,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                  spreadRadius: 8,
                  color: isLightMode
                      ? const Color(0x0F1F2329)
                      : Theme.of(context).shadowColor.withOpacity(0.06),
                ),
                BoxShadow(
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                  color: isLightMode
                      ? const Color(0x141F2329)
                      : Theme.of(context).shadowColor.withOpacity(0.08),
                ),
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: isLightMode
                      ? const Color(0x1F1F2329)
                      : Theme.of(context).shadowColor.withOpacity(0.12),
                ),
              ],
            ),
            child: Material(
              borderRadius: _borderRadius,
              color: Colors.transparent,
              borderOnForeground: false,
              child: InkWell(
                overlayColor: WidgetStateProperty.all(
                  AFThemeExtension.of(context).lightGreyHover,
                ),
                borderRadius: _borderRadius,
                onTap: onPressed,
                child: const SizedBox.square(
                  dimension: 32,
                  child: Center(
                    child: FlowySvg(
                      FlowySvgs.ai_scroll_to_bottom_s,
                      size: Size.square(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
