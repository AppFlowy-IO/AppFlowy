import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide UploadImageMenu;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

import 'cover_editor.dart';

const double kCoverHeight = 250.0;
const double kIconHeight = 60.0;
const double kToolbarHeight = 40.0; // with padding to the top

class DocumentHeaderBlockKeys {
  const DocumentHeaderBlockKeys._();

  static const String coverType = 'cover_selection_type';
  static const String coverDetails = 'cover_selection';
  static const String icon = 'selected_icon';
}

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

class DocumentHeaderNodeWidget extends StatefulWidget {
  const DocumentHeaderNodeWidget({
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
  State<DocumentHeaderNodeWidget> createState() =>
      _DocumentHeaderNodeWidgetState();
}

class _DocumentHeaderNodeWidgetState extends State<DocumentHeaderNodeWidget> {
  CoverType get coverType => CoverType.fromString(
        widget.node.attributes[DocumentHeaderBlockKeys.coverType],
      );
  String? get coverDetails =>
      widget.node.attributes[DocumentHeaderBlockKeys.coverDetails];
  String? get icon => widget.node.attributes[DocumentHeaderBlockKeys.icon];
  bool get hasIcon => viewIcon.isNotEmpty;
  bool get hasCover => coverType != CoverType.none;

  String viewIcon = '';
  late final ViewListener viewListener;

  @override
  void initState() {
    super.initState();
    final value = widget.view.icon.value;
    viewIcon = value.isNotEmpty ? value : icon ?? '';
    widget.node.addListener(_reload);
    viewListener = ViewListener(
      viewId: widget.view.id,
    )..start(
        onViewUpdated: (p0) {
          setState(() {
            viewIcon = p0.icon.value;
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
            onCoverChanged: _saveCover,
            node: widget.node,
            editorState: widget.editorState,
            hasCover: hasCover,
            hasIcon: hasIcon,
          ),
        ),
        if (hasCover)
          DocumentCover(
            editorState: widget.editorState,
            node: widget.node,
            coverType: coverType,
            coverDetails: coverDetails,
            onCoverChanged: (type, details) =>
                _saveCover(cover: (type, details)),
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
              onIconChanged: (icon) async {
                _saveCover(icon: icon);
              },
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

  Future<void> _saveCover({(CoverType, String?)? cover, String? icon}) {
    final transaction = widget.editorState.transaction;
    final Map<String, dynamic> attributes = {
      DocumentHeaderBlockKeys.coverType:
          widget.node.attributes[DocumentHeaderBlockKeys.coverType],
      DocumentHeaderBlockKeys.coverDetails:
          widget.node.attributes[DocumentHeaderBlockKeys.coverDetails],
      DocumentHeaderBlockKeys.icon:
          widget.node.attributes[DocumentHeaderBlockKeys.icon],
    };
    if (cover != null) {
      attributes[DocumentHeaderBlockKeys.coverType] = cover.$1.toString();
      attributes[DocumentHeaderBlockKeys.coverDetails] = cover.$2;
    }
    if (icon != null) {
      attributes[DocumentHeaderBlockKeys.icon] = icon;
      widget.onIconChanged(icon);
    }

    transaction.updateNode(widget.node, attributes);
    return widget.editorState.apply(transaction);
  }
}

@visibleForTesting
class DocumentHeaderToolbar extends StatefulWidget {
  final Node node;
  final EditorState editorState;
  final bool hasCover;
  final bool hasIcon;
  final Future<void> Function({(CoverType, String?)? cover, String? icon})
      onCoverChanged;

  const DocumentHeaderToolbar({
    required this.node,
    required this.editorState,
    required this.hasCover,
    required this.hasIcon,
    required this.onCoverChanged,
    super.key,
  });

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
          ? EditorStyleCustomizer.documentPadding
          : EdgeInsets.symmetric(
              horizontal: EditorStyleCustomizer.documentPadding.left - 6.0,
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
          onTap: () => widget.onCoverChanged(
            cover: PlatformExtension.isDesktopOrWeb
                ? (CoverType.asset, builtInAssetImages.first)
                : (CoverType.color, '0xffe8e0ff'),
          ),
          useIntrinsicWidth: true,
          leftIcon: const FlowySvg(FlowySvgs.image_s),
          text: FlowyText.regular(
            LocaleKeys.document_plugins_cover_addCover.tr(),
          ),
        ),
      );
    }

    if (widget.hasIcon) {
      children.add(
        FlowyButton(
          leftIconSize: const Size.square(18),
          onTap: () => widget.onCoverChanged(icon: ""),
          useIntrinsicWidth: true,
          leftIcon: const Icon(
            Icons.emoji_emotions_outlined,
            size: 18,
          ),
          text: FlowyText.regular(
            LocaleKeys.document_plugins_cover_removeIcon.tr(),
          ),
        ),
      );
    } else {
      Widget child = FlowyButton(
        leftIconSize: const Size.square(18),
        useIntrinsicWidth: true,
        leftIcon: const Icon(
          Icons.emoji_emotions_outlined,
          size: 18,
        ),
        text: FlowyText.regular(
          LocaleKeys.document_plugins_cover_addIcon.tr(),
        ),
        onTap: PlatformExtension.isDesktop
            ? null
            : () async {
                final result = await context.push<EmojiPickerResult>(
                  MobileEmojiPickerScreen.routeName,
                );
                if (result != null) {
                  widget.onCoverChanged(icon: result.emoji);
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
            return FlowyIconPicker(
              onSelected: (result) {
                widget.onCoverChanged(icon: result.emoji);
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
  final Node node;
  final EditorState editorState;
  final CoverType coverType;
  final String? coverDetails;
  final Future<void> Function(CoverType type, String? details) onCoverChanged;

  const DocumentCover({
    required this.editorState,
    required this.node,
    required this.coverType,
    required this.onCoverChanged,
    this.coverDetails,
    super.key,
  });

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
              child: _buildCoverImage(),
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
                          return ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 340,
                              minHeight: 80,
                            ),
                            child: UploadImageMenu(
                              supportTypes: const [
                                UploadImageType.color,
                                UploadImageType.local,
                                UploadImageType.url,
                                UploadImageType.unsplash,
                              ],
                              onSelectedLocalImage: (path) async {
                                context.pop();
                                widget.onCoverChanged(CoverType.file, path);
                              },
                              onSelectedAIImage: (_) {
                                throw UnimplementedError();
                              },
                              onSelectedNetworkImage: (url) async {
                                context.pop();
                                widget.onCoverChanged(CoverType.file, url);
                              },
                              onSelectedColor: (color) {
                                context.pop();
                                widget.onCoverChanged(CoverType.color, color);
                              },
                            ),
                          );
                        },
                      );
                    },
                    fillColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 32,
                    title: LocaleKeys.document_plugins_cover_changeCover.tr(),
                  ),
                ),
                const HSpace(8.0),
                SizedBox.square(
                  dimension: 32.0,
                  child: DeleteCoverButton(
                    onTap: () => widget.onCoverChanged(CoverType.none, null),
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
          return CachedNetworkImage(
            imageUrl: detail,
            fit: BoxFit.cover,
          );
        }
        final imageFile = File(detail);
        if (!imageFile.existsSync()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCoverChanged(CoverType.none, null);
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
            constraints: BoxConstraints.loose(const Size(380, 450)),
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
              return ChangeCoverPopover(
                node: widget.node,
                editorState: widget.editorState,
                onCoverChanged: (cover, selection) =>
                    widget.onCoverChanged(cover, selection),
              );
            },
          ),
          const HSpace(10),
          DeleteCoverButton(
            onTap: () => widget.onCoverChanged(CoverType.none, null),
          ),
        ],
      ),
    );
  }

  void setOverlayButtonsHidden(bool value) {
    if (isOverlayButtonsHidden == value) return;
    setState(() {
      isOverlayButtonsHidden = value;
    });
  }
}

@visibleForTesting
class DeleteCoverButton extends StatelessWidget {
  final VoidCallback onTap;
  const DeleteCoverButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final fillColor = PlatformExtension.isDesktopOrWeb
        ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
        : Theme.of(context).colorScheme.onSurfaceVariant;
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
  final Node node;
  final EditorState editorState;
  final String icon;
  final Future<void> Function(String icon) onIconChanged;

  const DocumentIcon({
    required this.node,
    required this.editorState,
    required this.icon,
    required this.onIconChanged,
    super.key,
  });

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
          return FlowyIconPicker(
            onSelected: (result) {
              widget.onIconChanged(result.emoji);
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
            widget.onIconChanged(result.emoji);
          }
        },
      );
    }

    return child;
  }
}
