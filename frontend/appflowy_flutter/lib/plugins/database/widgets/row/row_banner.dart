import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/row_action.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef OnSubmittedEmoji = void Function(String emoji);
const _kBannerActionHeight = 40.0;

class RowBanner extends StatefulWidget {
  final RowController rowController;
  final EditableCellBuilder cellBuilder;

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
  void dispose() {
    _isHovering.dispose();
    super.dispose();
  }

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
                  const VSpace(4),
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
    return SizedBox(
      height: _kBannerActionHeight,
      child: ValueListenableBuilder(
        valueListenable: isHovering,
        builder: (BuildContext context, bool isHovering, Widget? child) {
          if (!isHovering) {
            return const SizedBox.shrink();
          }

          return BlocBuilder<RowBannerBloc, RowBannerState>(
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (state.rowMeta.icon.isEmpty)
                    AddEmojiButton(
                      onTap: () => popoverController.show(),
                    )
                  else
                    RemoveEmojiButton(
                      onTap: () => context
                          .read<RowBannerBloc>()
                          .add(const RowBannerEvent.setIcon('')),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BannerTitle extends StatelessWidget {
  final EditableCellBuilder cellBuilder;
  final PopoverController popoverController;
  final RowController rowController;

  const _BannerTitle({
    required this.cellBuilder,
    required this.popoverController,
    required this.rowController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBannerBloc, RowBannerState>(
      builder: (context, state) {
        final children = <Widget>[
          if (state.rowMeta.icon.isNotEmpty)
            EmojiButton(
              emoji: state.rowMeta.icon,
              showEmojiPicker: () => popoverController.show(),
            ),
          const HSpace(4),
          if (state.primaryField != null)
            Expanded(
              child: cellBuilder.buildCustom(
                CellContext(
                  fieldId: state.primaryField!.id,
                  rowId: rowController.rowId,
                ),
                skinMap: EditableCellSkinMap(textSkin: _TitleSkin()),
              ),
            ),
        ];

        return AppFlowyPopover(
          controller: popoverController,
          triggerActions: PopoverTriggerFlags.none,
          direction: PopoverDirection.bottomWithLeftAligned,
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 300),
          popupBuilder: (popoverContext) => EmojiSelectionMenu(
            onSubmitted: (emoji) {
              popoverController.close();
              context.read<RowBannerBloc>().add(RowBannerEvent.setIcon(emoji));
            },
            onExit: () {},
          ),
          child: Row(children: children),
        );
      },
    );
  }
}

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

class AddEmojiButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddEmojiButton({
    super.key,
    required this.onTap,
  });

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
        onTap: onTap,
        margin: const EdgeInsets.all(4),
      ),
    );
  }
}

class RemoveEmojiButton extends StatelessWidget {
  final VoidCallback onTap;
  const RemoveEmojiButton({
    super.key,
    required this.onTap,
  });

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
        onTap: onTap,
        margin: const EdgeInsets.all(4),
      ),
    );
  }
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

class _TitleSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      maxLines: null,
      autofocus: true,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 28),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: LocaleKeys.grid_row_titlePlaceholder.tr(),
        isDense: true,
        isCollapsed: true,
      ),
    );
  }
}
