import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef RowBannerCellBuilder = Widget Function(String fieldId);

class RowBanner extends StatefulWidget {
  final String viewId;
  final RowMetaPB rowMeta;
  final RowBannerCellBuilder cellBuilder;
  const RowBanner({
    required this.viewId,
    required this.rowMeta,
    required this.cellBuilder,
    super.key,
  });

  @override
  State<RowBanner> createState() => _RowBannerState();
}

class _RowBannerState extends State<RowBanner> {
  final _isHovering = ValueNotifier(false);
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowBannerBloc>(
      create: (context) => RowBannerBloc(
        viewId: widget.viewId,
        rowMeta: widget.rowMeta,
      )..add(const RowBannerEvent.initial()),
      child: MouseRegion(
        onEnter: (event) => _isHovering.value = true,
        onExit: (event) => _isHovering.value = false,
        child: SizedBox(
          height: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
                child: _BannerAction(
                  isHovering: _isHovering,
                  popoverController: popoverController,
                ),
              ),
              _BannerTitle(
                cellBuilder: widget.cellBuilder,
                popoverController: popoverController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  final ValueNotifier<bool> isHovering;
  final PopoverController popoverController;
  const _BannerAction({
    required this.isHovering,
    required this.popoverController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isHovering,
      builder: (BuildContext context, bool value, Widget? child) {
        if (value) {
          return BlocBuilder<RowBannerBloc, RowBannerState>(
            builder: (context, state) {
              final children = <Widget>[];
              final rowMeta = state.rowMeta;
              if (rowMeta.icon.isEmpty) {
                children.add(
                  EmojiPickerButton(
                    showEmojiPicker: () => popoverController.show(),
                  ),
                );
              } else {
                children.add(
                  RemoveEmojiButton(
                    onRemoved: () {
                      context
                          .read<RowBannerBloc>()
                          .add(const RowBannerEvent.setIcon(''));
                    },
                  ),
                );
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

class _BannerTitle extends StatefulWidget {
  final RowBannerCellBuilder cellBuilder;
  final PopoverController popoverController;
  const _BannerTitle({
    required this.cellBuilder,
    required this.popoverController,
  });

  @override
  State<_BannerTitle> createState() => _BannerTitleState();
}

class _BannerTitleState extends State<_BannerTitle> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBannerBloc, RowBannerState>(
      builder: (context, state) {
        final children = <Widget>[];

        if (state.rowMeta.icon.isNotEmpty) {
          children.add(
            EmojiButton(
              emoji: state.rowMeta.icon,
              showEmojiPicker: () => widget.popoverController.show(),
            ),
          );
        }

        if (state.primaryField != null) {
          children.add(
            Expanded(
              child: widget.cellBuilder(state.primaryField!.id),
            ),
          );
        }

        return AppFlowyPopover(
          controller: widget.popoverController,
          triggerActions: PopoverTriggerFlags.none,
          direction: PopoverDirection.bottomWithLeftAligned,
          popupBuilder: (popoverContext) => _buildEmojiPicker((emoji) {
            context
                .read<RowBannerBloc>()
                .add(RowBannerEvent.setIcon(emoji.emoji));
            widget.popoverController.close();
          }),
          child: Row(children: children),
        );
      },
    );
  }
}

typedef OnSubmittedEmoji = void Function(Emoji emoji);
const _kBannerActionHeight = 40.0;

class EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback showEmojiPicker;

  const EmojiButton({
    required this.emoji,
    required this.showEmojiPicker,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBannerActionHeight,
      width: _kBannerActionHeight,
      child: FlowyButton(
        margin: EdgeInsets.zero,
        text: FlowyText.medium(
          emoji,
          fontSize: 30,
          textAlign: TextAlign.center,
        ),
        onTap: showEmojiPicker,
      ),
    );
  }
}

class EmojiPickerButton extends StatefulWidget {
  final VoidCallback showEmojiPicker;
  const EmojiPickerButton({
    super.key,
    required this.showEmojiPicker,
  });

  @override
  State<EmojiPickerButton> createState() => _EmojiPickerButtonState();
}

class _EmojiPickerButtonState extends State<EmojiPickerButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 160,
      child: FlowyButton(
        text: FlowyText.medium(
          LocaleKeys.document_plugins_cover_addIcon.tr(),
        ),
        leftIcon: const Icon(
          Icons.emoji_emotions,
          size: 16,
        ),
        onTap: widget.showEmojiPicker,
      ),
    );
  }
}

class RemoveEmojiButton extends StatelessWidget {
  final VoidCallback onRemoved;
  RemoveEmojiButton({
    super.key,
    required this.onRemoved,
  });

  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 160,
      child: FlowyButton(
        text: FlowyText.medium(
          LocaleKeys.document_plugins_cover_removeIcon.tr(),
        ),
        leftIcon: const Icon(
          Icons.emoji_emotions,
          size: 16,
        ),
        onTap: onRemoved,
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
