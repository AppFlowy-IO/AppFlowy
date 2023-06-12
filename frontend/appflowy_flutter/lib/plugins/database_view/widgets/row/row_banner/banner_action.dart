import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef RowBannerCellBuilder = Widget Function(String fieldId);

class RowBanner extends StatefulWidget {
  final String viewId;
  final String rowId;
  final RowBannerCellBuilder cellBuilder;
  const RowBanner({
    required this.viewId,
    required this.rowId,
    required this.cellBuilder,
    super.key,
  });

  @override
  State<RowBanner> createState() => _RowBannerState();
}

class _RowBannerState extends State<RowBanner> {
  final _isHovering = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowBannerBloc>(
      create: (context) => RowBannerBloc(
        viewId: widget.viewId,
        rowId: widget.rowId,
      )..add(const RowBannerEvent.initial()),
      child: MouseRegion(
        onEnter: (event) => _isHovering.value = true,
        onExit: (event) => _isHovering.value = false,
        child: SizedBox(
          height: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BannerAction(isHovering: _isHovering),
              _BannerTitle(primaryCellBuilder: widget.cellBuilder),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  final ValueNotifier<bool> isHovering;
  const _BannerAction({required this.isHovering});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isHovering,
      builder: (BuildContext context, bool value, Widget? child) {
        if (value) {
          return BlocBuilder<RowBannerBloc, RowBannerState>(
            builder: (context, state) {
              final children = <Widget>[];
              final rowMeta = state.rowMetaPB;
              if (rowMeta != null) {
                if (!rowMeta.hasIcon()) {
                  children.add(
                    EmojiPickerButton(
                      onSubmitted: (Emoji emoji) {},
                    ),
                  );
                }
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
          );
        } else {
          return const SizedBox(height: _kBannerActionHeight);
        }
      },
    );
  }
}

class _BannerTitle extends StatelessWidget {
  final RowBannerCellBuilder primaryCellBuilder;
  const _BannerTitle({required this.primaryCellBuilder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBannerBloc, RowBannerState>(
      builder: (context, state) {
        final children = <Widget>[];
        if (state.rowMetaPB?.hasIcon() ?? false) {
          children.add(const EmojiButton());
        }

        if (state.primaryField != null) {
          children.add(
            Expanded(
              child: primaryCellBuilder(state.primaryField!.id),
            ),
          );
        }

        return Row(
          children: children,
        );
      },
    );
  }
}

typedef OnSubmittedEmoji = void Function(Emoji emoji);
const _kBannerActionHeight = 30.0;

class EmojiButton extends StatelessWidget {
  const EmojiButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      icon: Icon(
        Icons.emoji_emotions,
        size: 16,
      ),
      onPressed: () {},
    );
  }
}

class EmojiPickerButton extends StatefulWidget {
  final OnSubmittedEmoji onSubmitted;
  const EmojiPickerButton({
    super.key,
    required this.onSubmitted,
  });

  @override
  State<EmojiPickerButton> createState() => _EmojiPickerButtonState();
}

class _EmojiPickerButtonState extends State<EmojiPickerButton> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (context) => _buildEmojiPicker(widget.onSubmitted),
      child: SizedBox(
        height: _kBannerActionHeight,
        width: 200,
        child: FlowyButton(
          text: FlowyText.medium(
            LocaleKeys.calendar_settings_layoutDateField.tr(),
          ),
          leftIcon: const Icon(
            Icons.emoji_emotions,
            size: 16,
          ),
          onTap: () => popoverController.show(),
        ),
      ),
    );
  }
}

Widget _buildEmojiPicker(OnSubmittedEmoji onSubmitted) {
  return SizedBox(
    height: 250,
    child: EmojiSelectionMenu(
      onSubmitted: onSubmitted,
      onExit: () {},
    ),
  );
}
