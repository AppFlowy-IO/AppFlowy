import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

Future<(PredefinedFormat, PredefinedTextFormat?)?> showChangeFormatBottomSheet(
  BuildContext context,
) {
  return showMobileBottomSheet<(PredefinedFormat, PredefinedTextFormat?)?>(
    context,
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
  PredefinedFormat predefinedFormat = PredefinedFormat.text;
  PredefinedTextFormat? predefinedTextFormat = PredefinedTextFormat.auto;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: DragHandle(),
          ),
        ),
        _Header(
          onCancel: () => Navigator.of(context).pop(),
          onDone: () => Navigator.of(context)
              .pop((predefinedFormat, predefinedTextFormat)),
        ),
        const Divider(height: 0.5, thickness: 0.5),
        _Body(
          predefinedFormat: predefinedFormat,
          predefinedTextFormat: predefinedTextFormat,
          onSelectPredefinedFormat: (p0, p1) {
            setState(() {
              predefinedFormat = p0;
              predefinedTextFormat = p1;
            });
          },
        ),
        const VSpace(28.0),
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
    return Container(
      height: 44.0,
      color: Theme.of(context).colorScheme.surface,
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
            child: FlowyText.medium(
              LocaleKeys.chat_changeFormat_actionButton.tr(),
              fontSize: 16.0,
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
    required this.predefinedTextFormat,
    required this.onSelectPredefinedFormat,
  });

  final PredefinedFormat predefinedFormat;
  final PredefinedTextFormat? predefinedTextFormat;
  final void Function(PredefinedFormat, PredefinedTextFormat?)
      onSelectPredefinedFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VSpace(16.0),
        _buildFormatButton(PredefinedFormat.text, true),
        _buildFormatButton(PredefinedFormat.textAndImage),
        _buildFormatButton(PredefinedFormat.image),
        const VSpace(32.0),
        Opacity(
          opacity: predefinedFormat.hasText ? 1 : 0,
          child: Column(
            children: [
              _buildTextFormatButton(PredefinedTextFormat.auto, true),
              _buildTextFormatButton(PredefinedTextFormat.bulletList),
              _buildTextFormatButton(PredefinedTextFormat.numberedList),
              _buildTextFormatButton(PredefinedTextFormat.table),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatButton(
    PredefinedFormat format, [
    bool isFirst = false,
  ]) {
    return FlowyOptionTile.checkbox(
      text: format.i18n,
      isSelected: format == predefinedFormat,
      showTopBorder: isFirst,
      leftIcon: FlowySvg(
        format.icon,
        size: format == PredefinedFormat.textAndImage
            ? const Size(21.0 / 16.0 * 20, 20)
            : const Size.square(20),
      ),
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
    );
  }

  Widget _buildTextFormatButton(
    PredefinedTextFormat format, [
    bool isFirst = false,
  ]) {
    return FlowyOptionTile.checkbox(
      text: format.i18n,
      isSelected: format == predefinedTextFormat,
      showTopBorder: isFirst,
      leftIcon: FlowySvg(
        format.icon,
        size: const Size.square(20),
      ),
      onTap: () {
        if (format == predefinedTextFormat) {
          return;
        }
        onSelectPredefinedFormat(predefinedFormat, format);
      },
    );
  }
}
