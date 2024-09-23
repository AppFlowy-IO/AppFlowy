import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_banner_bloc.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/text_card_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/row_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/plugins/shared/cover_type_ext.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide UploadImageMenu;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../../document/presentation/editor_plugins/plugins.dart';

const _coverHeight = 250.0;
const _iconHeight = 60.0;
const _toolbarHeight = 40.0;

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
  late final isLocalMode =
      (widget.userProfile?.authenticator ?? AuthenticatorPB.Local) ==
          AuthenticatorPB.Local;

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
      child: BlocBuilder<RowBannerBloc, RowBannerState>(
        builder: (context, state) {
          final hasCover = state.rowMeta.cover.data.isNotEmpty;
          final hasIcon = state.rowMeta.icon.isNotEmpty;

          return Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      SizedBox(
                        height: _calculateOverallHeight(hasIcon, hasCover),
                        width: constraints.maxWidth,
                        child: RowHeaderToolbar(
                          offset: GridSize.horizontalHeaderPadding + 20,
                          hasIcon: hasIcon,
                          hasCover: hasCover,
                          onIconChanged: (icon) {
                            if (icon != null) {
                              context
                                  .read<RowBannerBloc>()
                                  .add(RowBannerEvent.setIcon(icon));
                            }
                          },
                          onCoverChanged: (cover) {
                            if (cover != null) {
                              context
                                  .read<RowBannerBloc>()
                                  .add(RowBannerEvent.setCover(cover));
                            }
                          },
                        ),
                      ),
                      if (hasCover)
                        RowCover(
                          rowId: widget.rowController.rowId,
                          cover: state.rowMeta.cover,
                          userProfile: widget.userProfile,
                          onCoverChanged: (type, details, uploadType) {
                            if (details != null) {
                              context.read<RowBannerBloc>().add(
                                    RowBannerEvent.setCover(
                                      RowCoverPB(
                                        data: details,
                                        uploadType: uploadType,
                                        coverType: type.into(),
                                      ),
                                    ),
                                  );
                            } else {
                              context
                                  .read<RowBannerBloc>()
                                  .add(const RowBannerEvent.removeCover());
                            }
                          },
                          isLocalMode: isLocalMode,
                        ),
                      if (hasIcon)
                        Positioned(
                          left: GridSize.horizontalHeaderPadding + 20,
                          bottom: hasCover
                              ? _toolbarHeight - _iconHeight / 2
                              : _toolbarHeight,
                          child: RowIcon(
                            icon: state.rowMeta.icon,
                            onIconChanged: (icon) {
                              if (icon == null || icon.isEmpty) {
                                context
                                    .read<RowBannerBloc>()
                                    .add(const RowBannerEvent.setIcon(""));
                              } else {
                                context
                                    .read<RowBannerBloc>()
                                    .add(RowBannerEvent.setIcon(icon));
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              const VSpace(8),
              _BannerTitle(
                cellBuilder: widget.cellBuilder,
                rowController: widget.rowController,
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateOverallHeight(bool hasIcon, bool hasCover) {
    switch ((hasIcon, hasCover)) {
      case (true, true):
        return _coverHeight + _toolbarHeight;
      case (true, false):
        return 50 + _iconHeight + _toolbarHeight;
      case (false, true):
        return _coverHeight + _toolbarHeight;
      case (false, false):
        return _toolbarHeight;
    }
  }
}

class RowCover extends StatefulWidget {
  const RowCover({
    super.key,
    required this.rowId,
    required this.cover,
    this.userProfile,
    required this.onCoverChanged,
    this.isLocalMode = true,
  });

  final String rowId;
  final RowCoverPB cover;
  final UserProfilePB? userProfile;
  final void Function(
    CoverType type,
    String? details,
    FileUploadTypePB? uploadType,
  ) onCoverChanged;
  final bool isLocalMode;

  @override
  State<RowCover> createState() => _RowCoverState();
}

class _RowCoverState extends State<RowCover> {
  final popoverController = PopoverController();
  bool isOverlayButtonsHidden = true;
  bool isPopoverOpen = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _coverHeight,
      child: MouseRegion(
        onEnter: (_) => setState(() => isOverlayButtonsHidden = false),
        onExit: (_) => setState(() => isOverlayButtonsHidden = true),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: DesktopRowCover(
                cover: widget.cover,
                userProfile: widget.userProfile,
              ),
            ),
            if (!isOverlayButtonsHidden || isPopoverOpen)
              _buildCoverOverlayButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverOverlayButtons(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            offset: const Offset(0, 8),
            direction: PopoverDirection.bottomWithCenterAligned,
            constraints: const BoxConstraints(
              maxWidth: 540,
              maxHeight: 360,
              minHeight: 80,
            ),
            margin: EdgeInsets.zero,
            onClose: () => setState(() => isPopoverOpen = false),
            child: IntrinsicWidth(
              child: RoundedTextButton(
                height: 28.0,
                onPressed: () => popoverController.show(),
                hoverColor: Theme.of(context).colorScheme.surface,
                textColor: Theme.of(context).colorScheme.tertiary,
                fillColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.5),
                title: LocaleKeys.document_plugins_cover_changeCover.tr(),
              ),
            ),
            popupBuilder: (BuildContext popoverContext) {
              isPopoverOpen = true;

              return UploadImageMenu(
                limitMaximumImageSize: !widget.isLocalMode,
                supportTypes: const [
                  UploadImageType.color,
                  UploadImageType.local,
                  UploadImageType.url,
                  UploadImageType.unsplash,
                ],
                onSelectedAIImage: (_) => throw UnimplementedError(),
                onSelectedLocalImages: (files) {
                  popoverController.close();
                  if (files.isEmpty) {
                    return;
                  }

                  final item = files.map((file) => file.path).first;
                  onCoverChanged(
                    CoverType.file,
                    item,
                    widget.isLocalMode
                        ? FileUploadTypePB.LocalFile
                        : FileUploadTypePB.CloudFile,
                  );
                },
                onSelectedNetworkImage: (url) {
                  popoverController.close();
                  onCoverChanged(
                    CoverType.file,
                    url,
                    FileUploadTypePB.NetworkFile,
                  );
                },
                onSelectedColor: (color) {
                  popoverController.close();
                  onCoverChanged(
                    CoverType.color,
                    color,
                    FileUploadTypePB.LocalFile,
                  );
                },
              );
            },
          ),
          const HSpace(10),
          DeleteCoverButton(
            onTap: () => widget.onCoverChanged(CoverType.none, null, null),
          ),
        ],
      ),
    );
  }

  Future<void> onCoverChanged(
    CoverType type,
    String? details,
    FileUploadTypePB? uploadType,
  ) async {
    if (type == CoverType.file && details != null && !isURL(details)) {
      if (widget.isLocalMode) {
        details = await saveImageToLocalStorage(details);
      } else {
        // else we should save the image to cloud storage
        (details, _) = await saveImageToCloudStorage(details, widget.rowId);
      }
    }
    widget.onCoverChanged(type, details, uploadType);
  }
}

class DesktopRowCover extends StatefulWidget {
  const DesktopRowCover({super.key, required this.cover, this.userProfile});

  final RowCoverPB cover;
  final UserProfilePB? userProfile;

  @override
  State<DesktopRowCover> createState() => _DesktopRowCoverState();
}

class _DesktopRowCoverState extends State<DesktopRowCover> {
  RowCoverPB get cover => widget.cover;

  @override
  Widget build(BuildContext context) {
    if (cover.coverType == CoverTypePB.FileCover) {
      return SizedBox(
        height: _coverHeight,
        width: double.infinity,
        child: AFImage(
          url: cover.data,
          uploadType: cover.uploadType,
          userProfile: widget.userProfile,
        ),
      );
    }

    if (cover.coverType == CoverTypePB.AssetCover) {
      return SizedBox(
        height: _coverHeight,
        width: double.infinity,
        child: Image.asset(
          PageStyleCoverImageType.builtInImagePath(cover.data),
          fit: BoxFit.cover,
        ),
      );
    }

    if (cover.coverType == CoverTypePB.ColorCover) {
      final color = FlowyTint.fromId(cover.data)?.color(context) ??
          cover.data.tryToColor();
      return Container(
        height: _coverHeight,
        width: double.infinity,
        color: color,
      );
    }

    if (cover.coverType == CoverTypePB.GradientCover) {
      return Container(
        height: _coverHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: FlowyGradientColor.fromId(cover.data).linear,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class RowHeaderToolbar extends StatefulWidget {
  const RowHeaderToolbar({
    super.key,
    required this.offset,
    required this.hasIcon,
    required this.hasCover,
    required this.onIconChanged,
    required this.onCoverChanged,
  });

  final double offset;
  final bool hasIcon;
  final bool hasCover;

  /// Returns null if the icon is removed.
  ///
  final void Function(String? icon) onIconChanged;

  /// Returns null if the cover is removed.
  ///
  final void Function(RowCoverPB? cover) onCoverChanged;

  @override
  State<RowHeaderToolbar> createState() => _RowHeaderToolbarState();
}

class _RowHeaderToolbarState extends State<RowHeaderToolbar> {
  final popoverController = PopoverController();
  final bool isDesktop = UniversalPlatform.isDesktopOrWeb;

  bool isHidden = UniversalPlatform.isDesktopOrWeb;
  bool isPopoverOpen = false;

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      opaque: false,
      onEnter: (_) => setState(() => isHidden = false),
      onExit: isPopoverOpen ? null : (_) => setState(() => isHidden = true),
      child: Container(
        alignment: Alignment.bottomLeft,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: widget.offset),
        child: SizedBox(
          height: 28,
          child: Visibility(
            visible: !isHidden || isPopoverOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.hasCover)
                  FlowyButton(
                    resetHoverOnRebuild: false,
                    useIntrinsicWidth: true,
                    leftIconSize: const Size.square(18),
                    leftIcon: const FlowySvg(FlowySvgs.add_cover_s),
                    text: FlowyText.small(
                      LocaleKeys.document_plugins_cover_addCover.tr(),
                    ),
                    onTap: () => widget.onCoverChanged(
                      RowCoverPB(
                        data: isDesktop ? '1' : '0xffe8e0ff',
                        uploadType: FileUploadTypePB.LocalFile,
                        coverType: isDesktop
                            ? CoverTypePB.AssetCover
                            : CoverTypePB.ColorCover,
                      ),
                    ),
                  ),
                if (!widget.hasIcon)
                  AppFlowyPopover(
                    controller: popoverController,
                    onClose: () => setState(() => isPopoverOpen = false),
                    offset: const Offset(0, 8),
                    direction: PopoverDirection.bottomWithCenterAligned,
                    constraints: BoxConstraints.loose(const Size(360, 380)),
                    margin: EdgeInsets.zero,
                    triggerActions: PopoverTriggerFlags.none,
                    popupBuilder: (_) {
                      isPopoverOpen = true;
                      return FlowyIconEmojiPicker(
                        onSelectedEmoji: (result) {
                          widget.onIconChanged(result.emoji);
                          popoverController.close();
                        },
                      );
                    },
                    child: FlowyButton(
                      useIntrinsicWidth: true,
                      leftIconSize: const Size.square(18),
                      leftIcon: const FlowySvg(FlowySvgs.add_icon_s),
                      text: FlowyText.small(
                        widget.hasIcon
                            ? LocaleKeys.document_plugins_cover_removeIcon.tr()
                            : LocaleKeys.document_plugins_cover_addIcon.tr(),
                      ),
                      onTap: () async {
                        if (!isDesktop) {
                          final result = await context.push<EmojiPickerResult>(
                            MobileEmojiPickerScreen.routeName,
                          );

                          if (result != null) {
                            widget.onIconChanged(result.emoji);
                          }
                        } else {
                          popoverController.show();
                        }
                      },
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

class RowIcon extends StatefulWidget {
  const RowIcon({
    super.key,
    required this.icon,
    required this.onIconChanged,
  });

  final String icon;
  final void Function(String?) onIconChanged;

  @override
  State<RowIcon> createState() => _RowIconState();
}

class _RowIconState extends State<RowIcon> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    if (widget.icon.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppFlowyPopover(
      controller: controller,
      offset: const Offset(0, 8),
      direction: PopoverDirection.bottomWithCenterAligned,
      constraints: BoxConstraints.loose(const Size(360, 380)),
      margin: EdgeInsets.zero,
      popupBuilder: (_) => FlowyIconEmojiPicker(
        onSelectedEmoji: (result) {
          controller.close();
          widget.onIconChanged(result.emoji);
        },
      ),
      child: EmojiIconWidget(emoji: widget.icon),
    );
  }
}

class _BannerTitle extends StatelessWidget {
  const _BannerTitle({
    required this.cellBuilder,
    required this.rowController,
  });

  final EditableCellBuilder cellBuilder;
  final RowController rowController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBannerBloc, RowBannerState>(
      builder: (context, state) {
        final children = [
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

        return Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Row(children: children),
        );
      },
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
