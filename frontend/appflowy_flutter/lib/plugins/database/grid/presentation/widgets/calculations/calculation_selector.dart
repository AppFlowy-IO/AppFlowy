import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class CalculationSelector extends StatefulWidget {
  const CalculationSelector({
    super.key,
    required this.isSelected,
  });

  final bool isSelected;

  @override
  State<CalculationSelector> createState() => _CalculationSelectorState();
}

class _CalculationSelectorState extends State<CalculationSelector> {
  bool _isHovering = false;

  void _setHovering(bool isHovering) =>
      setState(() => _isHovering = isHovering);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: widget.isSelected || _isHovering ? 1 : 0,
        child: FlowyButton(
          radius: BorderRadius.zero,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: FlowyText(
                  LocaleKeys.grid_calculate.tr(),
                  color: Theme.of(context).hintColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const HSpace(8),
              FlowySvg(
                FlowySvgs.arrow_down_s,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
