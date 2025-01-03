import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

Future<PredefinedFormat?> showChangeFormatBottomSheet(
  BuildContext context,
) {
  return showMobileBottomSheet<PredefinedFormat?>(
    context,
    showDragHandle: true,
    builder: (context) => const _ChangeFormatBottomSheetContent(),
  );
}

class _ChangeFormatBottomSheetContent extends StatefulWidget {
  const _ChangeFormatBottomSheetContent();

  @override
  State<_ChangeFormatBottomSheetContent> createState() =>
      _ChangeFormatBottomSheetContentState();
}

class _ChangeFormatBottomSheetContentState
    extends State<_ChangeFormatBottomSheetContent> {
  PredefinedFormat predefinedFormat = const PredefinedFormat.auto();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          onCancel: () => Navigator.of(context).pop(),
          onDone: () => Navigator.of(context).pop(predefinedFormat),
        ),
        const VSpace(4.0),
        _Body(
          predefinedFormat: predefinedFormat,
          onSelectPredefinedFormat: (format) {
            setState(() => predefinedFormat = format);
          },
        ),
        const VSpace(16.0),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onCancel,
    required this.onDone,
  });

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBarBackButton(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              onTap: onCancel,
            ),
          ),
          Align(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              child: FlowyText(
                LocaleKeys.chat_changeFormat_actionButton.tr(),
                fontSize: 17.0,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AppBarDoneButton(
              onTap: onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.predefinedFormat,
    required this.onSelectPredefinedFormat,
  });

  final PredefinedFormat predefinedFormat;
  final void Function(PredefinedFormat) onSelectPredefinedFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFormatButton(ImageFormat.text, true),
        _buildFormatButton(ImageFormat.textAndImage),
        _buildFormatButton(ImageFormat.image),
        const VSpace(32.0),
        Opacity(
          opacity: predefinedFormat.imageFormat.hasText ? 1 : 0,
          child: Column(
            children: [
              _buildTextFormatButton(TextFormat.auto, true),
              _buildTextFormatButton(TextFormat.bulletList),
              _buildTextFormatButton(TextFormat.numberedList),
              _buildTextFormatButton(TextFormat.table),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatButton(
    ImageFormat format, [
    bool isFirst = false,
  ]) {
    return FlowyOptionTile.checkbox(
      text: format.i18n,
      isSelected: format == predefinedFormat.imageFormat,
      showTopBorder: isFirst,
      leftIcon: FlowySvg(
        format.icon,
        size: format == ImageFormat.textAndImage
            ? const Size(21.0 / 16.0 * 20, 20)
            : const Size.square(20),
      ),
      onTap: () {
        if (format == predefinedFormat.imageFormat) {
          return;
        }
        if (format.hasText) {
          final textFormat = predefinedFormat.textFormat ?? TextFormat.auto;
          onSelectPredefinedFormat(
            PredefinedFormat(imageFormat: format, textFormat: textFormat),
          );
        } else {
          onSelectPredefinedFormat(
            PredefinedFormat(imageFormat: format, textFormat: null),
          );
        }
      },
    );
  }

  Widget _buildTextFormatButton(
    TextFormat format, [
    bool isFirst = false,
  ]) {
    return FlowyOptionTile.checkbox(
      text: format.i18n,
      isSelected: format == predefinedFormat.textFormat,
      showTopBorder: isFirst,
      leftIcon: FlowySvg(
        format.icon,
        size: const Size.square(20),
      ),
      onTap: () {
        if (format == predefinedFormat.textFormat) {
          return;
        }
        onSelectPredefinedFormat(
          PredefinedFormat(
            imageFormat: predefinedFormat.imageFormat,
            textFormat: format,
          ),
        );
      },
    );
  }
}
