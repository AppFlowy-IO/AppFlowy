import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/desktop_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/migration/editor_migration.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide UploadImageMenu;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

const double kCoverHeight = 250.0;
const double kIconHeight = 60.0;
const double kToolbarHeight = 40.0; // with padding to the top

// Remove this widget if the desktop support immersive cover.
class DocumentHeaderBlockKeys {
  const DocumentHeaderBlockKeys._();

  static const String coverType = 'cover_selection_type';
  static const String coverDetails = 'cover_selection';
  static const String icon = 'selected_icon';
}

// for the version under 0.5.5, including 0.5.5
enum CoverType {
  none,
  color,
  file,
  asset;

  static CoverType fromString(String? value) {
    if (value == null) {
      return CoverType.none;
    }
    return CoverType.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => CoverType.none,
    );
  }
}

class DocumentCoverWidget extends StatefulWidget {
  const DocumentCoverWidget({
    super.key,
    required this.node,
    required this.editorState,
    required this.onIconChanged,
    required this.view,
  });

  final Node node;
  final EditorState editorState;
  final void Function(String icon) onIconChanged;
  final ViewPB view;

  @override
  State<DocumentCoverWidget> createState() => _DocumentCoverWidgetState();
}

class _DocumentCoverWidgetState extends State<DocumentCoverWidget> {
  CoverType get coverType => CoverType.fromString(
        widget.node.attributes[DocumentHeaderBlockKeys.coverType],
      );
  String? get coverDetails =>
      widget.node.attributes[DocumentHeaderBlockKeys.coverDetails];
  String? get icon => widget.node.attributes[DocumentHeaderBlockKeys.icon];
  bool get hasIcon => viewIcon.isNotEmpty;
  bool get hasCover =>
      coverType != CoverType.none ||
      (cover != null && cover?.type != PageStyleCoverImageType.none);

  String viewIcon = '';
  PageStyleCover? cover;
  late ViewPB view;
  late final ViewListener viewListener;

  @override
  void initState() {
    super.initState();
    final value = widget.view.icon.value;
    viewIcon = value.isNotEmpty ? value : icon ?? '';
    cover = widget.view.cover;
    view = widget.view;
    widget.node.addListener(_reload);
    viewListener = ViewListener(
      viewId: widget.view.id,
    )..start(
        onViewUpdated: (p0) {
          setState(() {
            viewIcon = p0.icon.value;
            cover = p0.cover;
            view = p0;
          });
        },
      );
  }

  @override
  void dispose() {
    viewListener.stop();
    widget.node.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: _calculateOverallHeight(),
          child: DocumentHeaderToolbar(
            onIconOrCoverChanged: _saveIconOrCover,
            node: widget.node,
            editorState: widget.editorState,
            hasCover: hasCover,
            hasIcon: hasIcon,
          ),
        ),
        if (hasCover)
          DocumentCover(
            view: view,
            editorState: widget.editorState,
            node: widget.node,
            coverType: coverType,
            coverDetails: coverDetails,
            onChangeCover: (type, details) =>
                _saveIconOrCover(cover: (type, details)),
          ),
        if (hasIcon)
          Positioned(
            left: PlatformExtension.isDesktopOrWeb ? 80 : 20,
            // if hasCover, there shouldn't be icons present so the icon can
            // be closer to the bottom.
            bottom:
                hasCover ? kToolbarHeight - kIconHeight / 2 : kToolbarHeight,
            child: DocumentIcon(
              editorState: widget.editorState,
              node: widget.node,
              icon: viewIcon,
              onChangeIcon: (icon) => _saveIconOrCover(icon: icon),
            ),
          ),
      ],
    );
  }

  double _calculateOverallHeight() {
    switch ((hasIcon, hasCover)) {
      case (true, true):
        return kCoverHeight + kToolbarHeight;
      case (true, false):
        return 50 + kIconHeight + kToolbarHeight;
      case (false, true):
        return kCoverHeight + kToolbarHeight;
      case (false, false):
        return kToolbarHeight;
    }
  }

  void _saveIconOrCover({(CoverType, String?)? cover, String? icon}) async {
    final transaction = widget.editorState.transaction;
    final coverType = widget.node.attributes[DocumentHeaderBlockKeys.coverType];
    final coverDetails =
        widget.node.attributes[DocumentHeaderBlockKeys.coverDetails];
    final Map<String, dynamic> attributes = {
      DocumentHeaderBlockKeys.coverType: coverType,
      DocumentHeaderBlockKeys.coverDetails: coverDetails,
      DocumentHeaderBlockKeys.icon:
          widget.node.attributes[DocumentHeaderBlockKeys.icon],
      CustomImageBlockKeys.imageType: '1',
    };
    if (cover != null) {
      attributes[DocumentHeaderBlockKeys.coverType] = cover.$1.toString();
      attributes[DocumentHeaderBlockKeys.coverDetails] = cover.$2;
    }
    if (icon != null) {
      attributes[DocumentHeaderBlockKeys.icon] = icon;
      widget.onIconChanged(icon);
    }

    // compatible with version <= 0.5.5.
    transaction.updateNode(widget.node, attributes);
    await widget.editorState.apply(transaction);

    // compatible with version > 0.5.5.
    EditorMigration.migrateCoverIfNeeded(
      widget.view,
      attributes,
      overwrite: true,
    );
  }
}

@visibleForTesting
class DocumentHeaderToolbar extends StatefulWidget {
  const DocumentHeaderToolbar({
    super.key,
    required this.node,
    required this.editorState,
    required this.hasCover,
    required this.hasIcon,
    required this.onIconOrCoverChanged,
  });

  final Node node;
  final EditorState editorState;
  final bool hasCover;
  final bool hasIcon;
  final void Function({(CoverType, String?)? cover, String? icon})
      onIconOrCoverChanged;

  @override
  State<DocumentHeaderToolbar> createState() => _DocumentHeaderToolbarState();
}

class _DocumentHeaderToolbarState extends State<DocumentHeaderToolbar> {
  bool isHidden = true;
  bool isPopoverOpen = false;

  final PopoverController _popoverController = PopoverController();

  @override
  void initState() {
    super.initState();

    isHidden = PlatformExtension.isDesktopOrWeb;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      alignment: Alignment.bottomLeft,
      width: double.infinity,
      padding: PlatformExtension.isDesktopOrWeb
          ? EdgeInsets.symmetric(
              horizontal: EditorStyleCustomizer.documentPadding.right,
            )
          : EdgeInsets.symmetric(
              horizontal: EditorStyleCustomizer.documentPadding.left,
            ),
      child: SizedBox(
        height: 28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buildRowChildren(),
        ),
      ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      child = MouseRegion(
        onEnter: (event) => setHidden(false),
        onExit: (event) {
          if (!isPopoverOpen) {
            setHidden(true);
          }
        },
        opaque: false,
        child: child,
      );
    }

    return child;
  }

  List<Widget> buildRowChildren() {
    if (isHidden || widget.hasCover && widget.hasIcon) {
      return [];
    }
    final List<Widget> children = [];

    if (!widget.hasCover) {
      children.add(
        FlowyButton(
          leftIconSize: const Size.square(18),
          onTap: () => widget.onIconOrCoverChanged(
            cover: PlatformExtension.isDesktopOrWeb
                ? (CoverType.asset, '1')
                : (CoverType.color, '0xffe8e0ff'),
          ),
          useIntrinsicWidth: true,
          leftIcon: const FlowySvg(FlowySvgs.add_cover_s),
          text: FlowyText.small(
            LocaleKeys.document_plugins_cover_addCover.tr(),
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    if (widget.hasIcon) {
      children.add(
        FlowyButton(
          onTap: () => widget.onIconOrCoverChanged(icon: ""),
          useIntrinsicWidth: true,
          leftIcon: const FlowySvg(FlowySvgs.add_icon_s),
          iconPadding: 4.0,
          text: FlowyText.small(
            LocaleKeys.document_plugins_cover_removeIcon.tr(),
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    } else {
      Widget child = FlowyButton(
        useIntrinsicWidth: true,
        leftIcon: const FlowySvg(FlowySvgs.add_icon_s),
        iconPadding: 4.0,
        text: FlowyText.small(
          LocaleKeys.document_plugins_cover_addIcon.tr(),
          color: Theme.of(context).hintColor,
        ),
        onTap: PlatformExtension.isDesktop
            ? null
            : () async {
                final result = await context.push<EmojiPickerResult>(
                  MobileEmojiPickerScreen.routeName,
                );
                if (result != null) {
                  widget.onIconOrCoverChanged(icon: result.emoji);
                }
              },
      );

      if (PlatformExtension.isDesktop) {
        child = AppFlowyPopover(
          onClose: () => isPopoverOpen = false,
          controller: _popoverController,
          offset: const Offset(0, 8),
          direction: PopoverDirection.bottomWithCenterAligned,
          constraints: BoxConstraints.loose(const Size(360, 380)),
          child: child,
          popupBuilder: (BuildContext popoverContext) {
            isPopoverOpen = true;
            return FlowyIconEmojiPicker(
              onSelected: (result) {
                widget.onIconOrCoverChanged(icon: result.emoji);
                _popoverController.close();
              },
            );
          },
        );
      }

      children.add(child);
    }

    return children;
  }

  void setHidden(bool value) {
    if (isHidden == value) return;
    setState(() {
      isHidden = value;
    });
  }
}

@visibleForTesting
class DocumentCover extends StatefulWidget {
  const DocumentCover({
    super.key,
    required this.view,
    required this.node,
    required this.editorState,
    required this.coverType,
    this.coverDetails,
    required this.onChangeCover,
  });

  final ViewPB view;
  final Node node;
  final EditorState editorState;
  final CoverType coverType;
  final String? coverDetails;
  final void Function(CoverType type, String? details) onChangeCover;

  @override
  State<DocumentCover> createState() => DocumentCoverState();
}

class DocumentCoverState extends State<DocumentCover> {
  bool isOverlayButtonsHidden = true;
  bool isPopoverOpen = false;
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return PlatformExtension.isDesktopOrWeb
        ? _buildDesktopCover()
        : _buildMobileCover();
  }

  Widget _buildDesktopCover() {
    return SizedBox(
      height: kCoverHeight,
      child: MouseRegion(
        onEnter: (event) => setOverlayButtonsHidden(false),
        onExit: (event) =>
            setOverlayButtonsHidden(isPopoverOpen ? false : true),
        child: Stack(
          children: [
            SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: DesktopCover(
                view: widget.view,
                editorState: widget.editorState,
                node: widget.node,
                coverType: widget.coverType,
                coverDetails: widget.coverDetails,
              ),
            ),
            if (!isOverlayButtonsHidden) _buildCoverOverlayButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCover() {
    return SizedBox(
      height: kCoverHeight,
      child: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: _buildCoverImage(),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: Row(
              children: [
                IntrinsicWidth(
                  child: RoundedTextButton(
                    fontSize: 14,
                    onPressed: () {
                      showMobileBottomSheet(
                        context,
                        showHeader: true,
                        showDragHandle: true,
                        showCloseButton: true,
                        title:
                            LocaleKeys.document_plugins_cover_changeCover.tr(),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 340,
                                minHeight: 80,
                              ),
                              child: UploadImageMenu(
                                limitMaximumImageSize: !_isLocalMode(),
                                supportTypes: const [
                                  UploadImageType.color,
                                  UploadImageType.local,
                                  UploadImageType.url,
                                  UploadImageType.unsplash,
                                ],
                                onSelectedLocalImages: (paths) async {
                                  context.pop();
                                  widget.onChangeCover(
                                    CoverType.file,
                                    paths.first,
                                  );
                                },
                                onSelectedAIImage: (_) {
                                  throw UnimplementedError();
                                },
                                onSelectedNetworkImage: (url) async {
                                  context.pop();
                                  widget.onChangeCover(CoverType.file, url);
                                },
                                onSelectedColor: (color) {
                                  context.pop();
                                  widget.onChangeCover(CoverType.color, color);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    fillColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
                    height: 32,
                    title: LocaleKeys.document_plugins_cover_changeCover.tr(),
                  ),
                ),
                const HSpace(8.0),
                SizedBox.square(
                  dimension: 32.0,
                  child: DeleteCoverButton(
                    onTap: () => widget.onChangeCover(CoverType.none, null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final detail = widget.coverDetails;
    if (detail == null) {
      return const SizedBox.shrink();
    }
    switch (widget.coverType) {
      case CoverType.file:
        if (isURL(detail)) {
          final userProfilePB =
              context.read<DocumentBloc>().state.userProfilePB;
          return FlowyNetworkImage(
            url: detail,
            userProfilePB: userProfilePB,
            errorWidgetBuilder: (context, url, error) =>
                const SizedBox.shrink(),
          );
        }
        final imageFile = File(detail);
        if (!imageFile.existsSync()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChangeCover(CoverType.none, null);
          });
          return const SizedBox.shrink();
        }
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
        );
      case CoverType.asset:
        return Image.asset(
          widget.coverDetails!,
          fit: BoxFit.cover,
        );
      case CoverType.color:
        final color = widget.coverDetails?.tryToColor() ?? Colors.white;
        return Container(color: color);
      case CoverType.none:
        return const SizedBox.shrink();
    }
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
            onClose: () => isPopoverOpen = false,
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
                limitMaximumImageSize: !_isLocalMode(),
                supportTypes: const [
                  UploadImageType.color,
                  UploadImageType.local,
                  UploadImageType.url,
                  UploadImageType.unsplash,
                ],
                onSelectedLocalImages: (paths) {
                  popoverController.close();
                  onCoverChanged(CoverType.file, paths.first);
                },
                onSelectedAIImage: (_) {
                  throw UnimplementedError();
                },
                onSelectedNetworkImage: (url) {
                  popoverController.close();
                  onCoverChanged(CoverType.file, url);
                },
                onSelectedColor: (color) {
                  popoverController.close();
                  onCoverChanged(CoverType.color, color);
                },
              );
            },
          ),
          const HSpace(10),
          DeleteCoverButton(
            onTap: () => onCoverChanged(CoverType.none, null),
          ),
        ],
      ),
    );
  }

  Future<void> onCoverChanged(CoverType type, String? details) async {
    if (type == CoverType.file && details != null && !isURL(details)) {
      if (_isLocalMode()) {
        details = await saveImageToLocalStorage(details);
      } else {
        // else we should save the image to cloud storage
        (details, _) = await saveImageToCloudStorage(details, widget.view.id);
      }
    }
    widget.onChangeCover(type, details);
  }

  void setOverlayButtonsHidden(bool value) {
    if (isOverlayButtonsHidden == value) return;
    setState(() {
      isOverlayButtonsHidden = value;
    });
  }

  bool _isLocalMode() {
    return context.read<DocumentBloc>().isLocalMode;
  }
}

@visibleForTesting
class DeleteCoverButton extends StatelessWidget {
  const DeleteCoverButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fillColor = PlatformExtension.isDesktopOrWeb
        ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);
    final svgColor = PlatformExtension.isDesktopOrWeb
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.onPrimary;
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.surface,
      fillColor: fillColor,
      iconPadding: const EdgeInsets.all(5),
      width: 28,
      icon: FlowySvg(
        FlowySvgs.delete_s,
        color: svgColor,
      ),
      onPressed: onTap,
    );
  }
}

@visibleForTesting
class DocumentIcon extends StatefulWidget {
  const DocumentIcon({
    super.key,
    required this.node,
    required this.editorState,
    required this.icon,
    required this.onChangeIcon,
  });

  final Node node;
  final EditorState editorState;
  final String icon;
  final void Function(String icon) onChangeIcon;

  @override
  State<DocumentIcon> createState() => _DocumentIconState();
}

class _DocumentIconState extends State<DocumentIcon> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    Widget child = EmojiIconWidget(
      emoji: widget.icon,
    );

    if (PlatformExtension.isDesktopOrWeb) {
      child = AppFlowyPopover(
        direction: PopoverDirection.bottomWithCenterAligned,
        controller: _popoverController,
        offset: const Offset(0, 8),
        constraints: BoxConstraints.loose(const Size(360, 380)),
        child: child,
        popupBuilder: (BuildContext popoverContext) {
          return FlowyIconEmojiPicker(
            onSelected: (result) {
              widget.onChangeIcon(result.emoji);
              _popoverController.close();
            },
          );
        },
      );
    } else {
      child = GestureDetector(
        child: child,
        onTap: () async {
          final result = await context.push<EmojiPickerResult>(
            MobileEmojiPickerScreen.routeName,
          );
          if (result != null) {
            widget.onChangeIcon(result.emoji);
          }
        },
      );
    }

    return child;
  }
}
