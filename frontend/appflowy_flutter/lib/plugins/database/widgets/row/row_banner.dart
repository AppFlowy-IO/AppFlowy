import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/text_card_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/row_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kBannerActionHeight = 40.0;

class RowBanner extends StatefulWidget {
  const RowBanner({
    super.key,
    required this.databaseController,
    required this.rowController,
    required this.cellBuilder,
    this.allowOpenAsFullPage = true,
    this.userProfile,
  });

  final DatabaseController databaseController;
  final RowController rowController;
  final EditableCellBuilder cellBuilder;
  final bool allowOpenAsFullPage;
  final UserProfilePB? userProfile;

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
        fieldController: widget.databaseController.fieldController,
        rowMeta: widget.rowController.rowMeta,
      )..add(const RowBannerEvent.initial()),
      child: Builder(
        builder: (context) => MouseRegion(
          onEnter: (event) => _isHovering.value = true,
          onExit: (event) => _isHovering.value = false,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BannerCover(userProfile: widget.userProfile),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    60,
                    context.watch<RowBannerBloc>().hasCover ? 4 : 34,
                    60,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                        child: _BannerAction(
                          rowId: widget.rowController.rowId,
                          isHovering: _isHovering,
                          popoverController: popoverController,
                        ),
                      ),
                      const VSpace(8),
                      _BannerTitle(
                        cellBuilder: widget.cellBuilder,
                        popoverController: popoverController,
                        rowController: widget.rowController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatefulWidget {
  const _BannerAction({
    required this.isHovering,
    required this.popoverController,
    required this.rowId,
  });

  final ValueNotifier<bool> isHovering;
  final PopoverController popoverController;
  final String rowId;

  @override
  State<_BannerAction> createState() => _BannerActionState();
}

class _BannerActionState extends State<_BannerAction> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBannerActionHeight,
      child: ValueListenableBuilder(
        valueListenable: widget.isHovering,
        builder: (BuildContext context, bool isHovering, Widget? child) {
          if (!isHovering && !isSelected) {
            return const SizedBox.shrink();
          }

          return BlocBuilder<RowBannerBloc, RowBannerState>(
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.rowMeta.icon.isEmpty)
                    AddEmojiButton(
                      onTap: () => widget.popoverController.show(),
                    )
                  else
                    RemoveEmojiButton(
                      onTap: () => context
                          .read<RowBannerBloc>()
                          .add(const RowBannerEvent.setIcon('')),
                    ),
                  const HSpace(8),
                  if (state.rowMeta.cover.url.isEmpty)
                    AddCoverButton(
                      rowId: widget.rowId,
                      onPopoverChanged: (isShowing) {
                        isSelected = isShowing;

                        if (!isShowing) {
                          setState(() {});
                        }
                      },
                    )
                  else
                    RemoveCoverButton(
                      onTap: () => context
                          .read<RowBannerBloc>()
                          .add(const RowBannerEvent.removeCover()),
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
  const _BannerTitle({
    required this.cellBuilder,
    required this.popoverController,
    required this.rowController,
  });

  final EditableCellBuilder cellBuilder;
  final PopoverController popoverController;
  final RowController rowController;

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

@visibleForTesting
class BannerCover extends StatelessWidget {
  const BannerCover({super.key, required this.userProfile});

  final UserProfilePB? userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBannerBloc, RowBannerState>(
      buildWhen: (prev, curr) =>
          prev.rowMeta.cover.url != curr.rowMeta.cover.url,
      builder: (context, state) {
        final cover = state.rowMeta.cover;
        if (cover.url.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 250,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: AFImage(
                    url: cover.url,
                    uploadType: cover.uploadType,
                    userProfile: userProfile,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class EmojiButton extends StatelessWidget {
  const EmojiButton({
    super.key,
    required this.emoji,
    required this.showEmojiPicker,
  });

  final String emoji;
  final VoidCallback showEmojiPicker;

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

class AddCoverButton extends StatelessWidget {
  const AddCoverButton({
    super.key,
    required this.rowId,
    required this.onPopoverChanged,
  });

  final String rowId;
  final void Function(bool) onPopoverChanged;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 5),
      onOpen: () => onPopoverChanged(true),
      onClose: () => onPopoverChanged(false),
      popupBuilder: (_) => BlocProvider.value(
        value: context.read<RowBannerBloc>(),
        child: Builder(
          builder: (context) {
            return UploadImageMenu(
              supportTypes: const [UploadImageType.local, UploadImageType.url],
              onSelectedLocalImages: (images) async {
                if (images.isEmpty) {
                  return;
                }

                final image = images.first;
                await insertLocalFile(
                  context,
                  image,
                  userProfile: context.read<RowBannerBloc>().userProfile,
                  documentId: rowId,
                  onUploadSuccess: (url, isLocalMode) {
                    context.read<RowBannerBloc>().add(
                          RowBannerEvent.setCover(
                            RowCoverPB(
                              url: url,
                              uploadType: isLocalMode
                                  ? FileUploadTypePB.LocalFile
                                  : FileUploadTypePB.CloudFile,
                            ),
                          ),
                        );
                  },
                );
                onPopoverChanged(false);
              },
              onSelectedNetworkImage: (String url) {
                context.read<RowBannerBloc>().add(
                      RowBannerEvent.setCover(
                        RowCoverPB(
                          url: url,
                          uploadType: FileUploadTypePB.NetworkFile,
                        ),
                      ),
                    );
                onPopoverChanged(false);
              },
              onSelectedAIImage: (_) {},
            );
          },
        ),
      ),
      child: SizedBox(
        height: 26,
        child: FlowyButton(
          useIntrinsicWidth: true,
          text: FlowyText.medium(
            lineHeight: 1.0,
            LocaleKeys.document_plugins_cover_addCover.tr(),
          ),
          leftIcon: const FlowySvg(FlowySvgs.image_s),
          margin: const EdgeInsets.all(4),
        ),
      ),
    );
  }
}

class AddEmojiButton extends StatelessWidget {
  const AddEmojiButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.medium(
          lineHeight: 1.0,
          LocaleKeys.document_plugins_cover_addIcon.tr(),
        ),
        leftIcon: const FlowySvg(FlowySvgs.emoji_s),
        onTap: onTap,
        margin: const EdgeInsets.all(4),
      ),
    );
  }
}

class RemoveCoverButton extends StatelessWidget {
  const RemoveCoverButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.medium(
          lineHeight: 1.0,
          LocaleKeys.document_plugins_cover_removeCover.tr(),
        ),
        leftIcon: const FlowySvg(FlowySvgs.image_s),
        onTap: onTap,
        margin: const EdgeInsets.all(4),
      ),
    );
  }
}

class RemoveEmojiButton extends StatelessWidget {
  const RemoveEmojiButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.medium(
          lineHeight: 1.0,
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
  const RowActionButton({super.key, required this.rowController});

  final RowController rowController;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (context) => RowActionList(rowController: rowController),
      child: FlowyTooltip(
        message: LocaleKeys.grid_rowPage_moreRowActions.tr(),
        child: FlowyIconButton(
          width: 20,
          height: 20,
          icon: const FlowySvg(FlowySvgs.details_horizontal_s),
          iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        ),
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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            focusNode.unfocus(),
        const SimpleActivator(LogicalKeyboardKey.enter): () =>
            focusNode.unfocus(),
      },
      child: TextField(
        controller: textEditingController,
        focusNode: focusNode,
        autofocus: true,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 28),
        maxLines: null,
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
        onEditingComplete: () {
          bloc.add(TextCellEvent.updateText(textEditingController.text));
        },
      ),
    );
  }
}
