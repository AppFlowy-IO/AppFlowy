import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_action.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';
import 'cells/cells.dart';

class RowBanner extends StatefulWidget {
  final RowController rowController;
  final GridCellBuilder cellBuilder;

  const RowBanner({
    required this.rowController,
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
        viewId: widget.rowController.viewId,
        rowMeta: widget.rowController.rowMeta,
      )..add(const RowBannerEvent.initial()),
      child: MouseRegion(
        onEnter: (event) => _isHovering.value = true,
        onExit: (event) => _isHovering.value = false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 34, 60, 0),
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
                  const HSpace(4),
                  _BannerTitle(
                    cellBuilder: widget.cellBuilder,
                    popoverController: popoverController,
                    rowController: widget.rowController,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: RowActionButton(rowController: widget.rowController),
            ),
          ],
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
        if (!value) {
          return const SizedBox(height: _kBannerActionHeight);
        }

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
      },
    );
  }
}

class _BannerTitle extends StatefulWidget {
  final GridCellBuilder cellBuilder;
  final PopoverController popoverController;
  final RowController rowController;

  const _BannerTitle({
    required this.cellBuilder,
    required this.popoverController,
    required this.rowController,
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

        children.add(const HSpace(4));

        if (state.primaryField != null) {
          final style = GridTextCellStyle(
            placeholder: LocaleKeys.grid_row_titlePlaceholder.tr(),
            textStyle: Theme.of(context).textTheme.titleLarge,
            showEmoji: false,
            autofocus: true,
            cellPadding: EdgeInsets.zero,
          );
          final cellContext = DatabaseCellContext(
            viewId: widget.rowController.viewId,
            rowMeta: widget.rowController.rowMeta,
            fieldInfo: FieldInfo.initial(state.primaryField!),
          );
          children.add(
            Expanded(
              child: widget.cellBuilder.build(cellContext, style: style),
            ),
          );
        }

        return AppFlowyPopover(
          controller: widget.popoverController,
          triggerActions: PopoverTriggerFlags.none,
          direction: PopoverDirection.bottomWithLeftAligned,
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 300),
          popupBuilder: (popoverContext) => _buildEmojiPicker((emoji) {
            context.read<RowBannerBloc>().add(RowBannerEvent.setIcon(emoji));
            widget.popoverController.close();
          }),
          child: Row(children: children),
        );
      },
    );
  }
}

typedef OnSubmittedEmoji = void Function(String emoji);
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
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.medium(
          LocaleKeys.document_plugins_cover_addIcon.tr(),
        ),
        leftIcon: const FlowySvg(FlowySvgs.emoji_s),
        onTap: widget.showEmojiPicker,
        margin: const EdgeInsets.all(4),
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
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.medium(
          LocaleKeys.document_plugins_cover_removeIcon.tr(),
        ),
        leftIcon: const FlowySvg(FlowySvgs.emoji_s),
        onTap: onRemoved,
        margin: const EdgeInsets.all(4),
      ),
    );
  }
}

Widget _buildEmojiPicker(OnSubmittedEmoji onSubmitted) {
  return EmojiSelectionMenu(
    onSubmitted: onSubmitted,
    onExit: () {},
  );
}

class RowActionButton extends StatelessWidget {
  final RowController rowController;
  const RowActionButton({super.key, required this.rowController});

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (context) => RowActionList(rowController: rowController),
      child: FlowyIconButton(
        width: 20,
        height: 20,
        icon: const FlowySvg(FlowySvgs.details_horizontal_s),
        iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }
}
