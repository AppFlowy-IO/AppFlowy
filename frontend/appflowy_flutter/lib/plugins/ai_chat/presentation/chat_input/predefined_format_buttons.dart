import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import '../layout_define.dart';

class PromptInputDesktopToggleFormatButton extends StatelessWidget {
  const PromptInputDesktopToggleFormatButton({
    super.key,
    required this.showFormatBar,
    required this.predefinedFormat,
    required this.predefinedTextFormat,
    required this.onTap,
  });

  final bool showFormatBar;
  final PredefinedFormat predefinedFormat;
  final PredefinedTextFormat? predefinedTextFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: DesktopAIPromptSizes.actionBarButtonSize,
        child: FlowyHover(
          style: const HoverStyle(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(6.0),
            child: FlowyText(
              _getDescription(),
              fontSize: 12.0,
              figmaLineHeight: 16.0,
            ),
          ),
        ),
      ),
    );
  }

  String _getDescription() {
    if (!showFormatBar) {
      return LocaleKeys.chat_changeFormat_blankDescription.tr();
    }

    return switch ((predefinedFormat, predefinedTextFormat)) {
      (PredefinedFormat.image, _) => predefinedFormat.i18n,
      (PredefinedFormat.text, PredefinedTextFormat.auto) =>
        LocaleKeys.chat_changeFormat_defaultDescription.tr(),
      (PredefinedFormat.text, _) when predefinedTextFormat != null =>
        predefinedTextFormat!.i18n,
      (PredefinedFormat.textAndImage, PredefinedTextFormat.auto) =>
        LocaleKeys.chat_changeFormat_textWithImageDescription.tr(),
      (PredefinedFormat.textAndImage, PredefinedTextFormat.bulletList) =>
        LocaleKeys.chat_changeFormat_bulletWithImageDescription.tr(),
      (PredefinedFormat.textAndImage, PredefinedTextFormat.numberedList) =>
        LocaleKeys.chat_changeFormat_numberWithImageDescription.tr(),
      (PredefinedFormat.textAndImage, PredefinedTextFormat.table) =>
        LocaleKeys.chat_changeFormat_tableWithImageDescription.tr(),
      _ => throw UnimplementedError(),
    };
  }
}

class ChangeFormatBar extends StatelessWidget {
  const ChangeFormatBar({
    super.key,
    required this.predefinedFormat,
    required this.predefinedTextFormat,
    required this.buttonSize,
    required this.iconSize,
    required this.spacing,
    required this.onSelectPredefinedFormat,
  });

  final PredefinedFormat predefinedFormat;
  final PredefinedTextFormat? predefinedTextFormat;
  final double buttonSize;
  final double iconSize;
  final double spacing;
  final void Function(PredefinedFormat, PredefinedTextFormat?)
      onSelectPredefinedFormat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesktopAIPromptSizes.predefinedFormatButtonHeight,
      child: SeparatedRow(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => HSpace(spacing),
        children: [
          _buildFormatButton(context, PredefinedFormat.text),
          _buildFormatButton(context, PredefinedFormat.textAndImage),
          _buildFormatButton(context, PredefinedFormat.image),
          if (predefinedFormat.hasText) ...[
            _buildDivider(),
            _buildTextFormatButton(context, PredefinedTextFormat.auto),
            _buildTextFormatButton(context, PredefinedTextFormat.bulletList),
            _buildTextFormatButton(context, PredefinedTextFormat.numberedList),
            _buildTextFormatButton(context, PredefinedTextFormat.table),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatButton(BuildContext context, PredefinedFormat format) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (format == predefinedFormat) {
          return;
        }
        if (format.hasText) {
          final textFormat = predefinedTextFormat ?? PredefinedTextFormat.auto;
          onSelectPredefinedFormat(format, textFormat);
        } else {
          onSelectPredefinedFormat(format, null);
        }
      },
      child: FlowyTooltip(
        message: format.i18n,
        child: SizedBox.square(
          dimension: buttonSize,
          child: FlowyHover(
            isSelected: () => format == predefinedFormat,
            child: Center(
              child: FlowySvg(
                format.icon,
                size: format == PredefinedFormat.textAndImage
                    ? Size(21.0 / 16.0 * iconSize, iconSize)
                    : Size.square(iconSize),
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
    PredefinedTextFormat format,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (format == predefinedTextFormat) {
          return;
        }
        onSelectPredefinedFormat(predefinedFormat, format);
      },
      child: FlowyTooltip(
        message: format.i18n,
        child: SizedBox.square(
          dimension: buttonSize,
          child: FlowyHover(
            isSelected: () => format == predefinedTextFormat,
            child: Center(
              child: FlowySvg(
                format.icon,
                size: Size.square(iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PromptInputMobileToggleFormatButton extends StatelessWidget {
  const PromptInputMobileToggleFormatButton({
    super.key,
    required this.showFormatBar,
    required this.predefinedFormat,
    required this.predefinedTextFormat,
    required this.onTap,
  });

  final bool showFormatBar;
  final PredefinedFormat predefinedFormat;
  final PredefinedTextFormat? predefinedTextFormat;
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
                FlowySvgs.ai_text_auto_s,
                size: Size.square(24.0),
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
