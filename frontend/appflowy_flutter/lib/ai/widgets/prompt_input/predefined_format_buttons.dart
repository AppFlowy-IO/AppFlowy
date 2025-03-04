import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../service/ai_entities.dart';
import 'layout_define.dart';

class PromptInputDesktopToggleFormatButton extends StatelessWidget {
  const PromptInputDesktopToggleFormatButton({
    super.key,
    required this.showFormatBar,
    required this.onTap,
  });

  final bool showFormatBar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText: showFormatBar
          ? LocaleKeys.chat_changeFormat_defaultDescription.tr()
          : LocaleKeys.chat_changeFormat_blankDescription.tr(),
      width: 28.0,
      onPressed: onTap,
      icon: showFormatBar
          ? const FlowySvg(
              FlowySvgs.m_aa_text_s,
              size: Size.square(16.0),
              color: Color(0xFF666D76),
            )
          : const FlowySvg(
              FlowySvgs.ai_text_image_s,
              size: Size(21.0, 16.0),
              color: Color(0xFF666D76),
            ),
    );
  }
}

class ChangeFormatBar extends StatelessWidget {
  const ChangeFormatBar({
    super.key,
    required this.predefinedFormat,
    required this.spacing,
    required this.onSelectPredefinedFormat,
  });

  final PredefinedFormat? predefinedFormat;
  final double spacing;
  final void Function(PredefinedFormat) onSelectPredefinedFormat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesktopAIPromptSizes.predefinedFormatButtonHeight,
      child: SeparatedRow(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => HSpace(spacing),
        children: [
          _buildFormatButton(context, ImageFormat.text),
          _buildFormatButton(context, ImageFormat.textAndImage),
          _buildFormatButton(context, ImageFormat.image),
          if (predefinedFormat?.imageFormat.hasText ?? true) ...[
            _buildDivider(),
            _buildTextFormatButton(context, TextFormat.paragraph),
            _buildTextFormatButton(context, TextFormat.bulletList),
            _buildTextFormatButton(context, TextFormat.numberedList),
            _buildTextFormatButton(context, TextFormat.table),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatButton(BuildContext context, ImageFormat format) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (predefinedFormat != null &&
            format == predefinedFormat!.imageFormat) {
          return;
        }
        if (format.hasText) {
          final textFormat =
              predefinedFormat?.textFormat ?? TextFormat.paragraph;
          onSelectPredefinedFormat(
            PredefinedFormat(imageFormat: format, textFormat: textFormat),
          );
        } else {
          onSelectPredefinedFormat(
            PredefinedFormat(imageFormat: format, textFormat: null),
          );
        }
      },
      child: FlowyTooltip(
        message: format.i18n,
        child: SizedBox.square(
          dimension: _buttonSize,
          child: FlowyHover(
            isSelected: () => format == predefinedFormat?.imageFormat,
            child: Center(
              child: FlowySvg(
                format.icon,
                size: format == ImageFormat.textAndImage
                    ? Size(21.0 / 16.0 * _iconSize, _iconSize)
                    : Size.square(_iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return VerticalDivider(
      indent: 6.0,
      endIndent: 6.0,
      width: 1.0 + spacing * 2,
    );
  }

  Widget _buildTextFormatButton(
    BuildContext context,
    TextFormat format,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (predefinedFormat != null &&
            format == predefinedFormat!.textFormat) {
          return;
        }
        onSelectPredefinedFormat(
          PredefinedFormat(
            imageFormat: predefinedFormat?.imageFormat ?? ImageFormat.text,
            textFormat: format,
          ),
        );
      },
      child: FlowyTooltip(
        message: format.i18n,
        child: SizedBox.square(
          dimension: _buttonSize,
          child: FlowyHover(
            isSelected: () => format == predefinedFormat?.textFormat,
            child: Center(
              child: FlowySvg(
                format.icon,
                size: Size.square(_iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get _buttonSize {
    return UniversalPlatform.isMobile
        ? MobileAIPromptSizes.predefinedFormatButtonHeight
        : DesktopAIPromptSizes.predefinedFormatButtonHeight;
  }

  double get _iconSize {
    return UniversalPlatform.isMobile
        ? MobileAIPromptSizes.predefinedFormatIconHeight
        : DesktopAIPromptSizes.predefinedFormatIconHeight;
  }
}

class PromptInputMobileToggleFormatButton extends StatelessWidget {
  const PromptInputMobileToggleFormatButton({
    super.key,
    required this.showFormatBar,
    required this.onTap,
  });

  final bool showFormatBar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32.0,
      child: FlowyButton(
        radius: const BorderRadius.all(Radius.circular(8.0)),
        margin: EdgeInsets.zero,
        expandText: false,
        text: showFormatBar
            ? const FlowySvg(
                FlowySvgs.m_aa_text_s,
                size: Size.square(20.0),
              )
            : const FlowySvg(
                FlowySvgs.ai_text_image_s,
                size: Size(26.25, 20.0),
              ),
        onTap: onTap,
      ),
    );
  }
}
