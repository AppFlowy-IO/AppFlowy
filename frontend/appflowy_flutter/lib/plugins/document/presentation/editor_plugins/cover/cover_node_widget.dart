import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide FlowySvg;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';

import 'change_cover_popover.dart';
import 'emoji_icon_widget.dart';
import 'emoji_popover.dart';

const double kCoverHeight = 250.0;

class CoverBlockKeys {
  const CoverBlockKeys._();

  static const String selectionType = 'cover_selection_type';
  static const String selection = 'cover_selection';
  static const String iconSelection = 'selected_icon';
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

class CoverNodeWidgetBuilder implements NodeWidgetBuilder {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return CoverImageNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (_) => true;
}

class CoverImageNodeWidget extends StatefulWidget {
  const CoverImageNodeWidget({
    required this.node,
    required this.editorState,
    super.key,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<CoverImageNodeWidget> createState() => _CoverImageNodeWidgetState();
}

class _CoverImageNodeWidgetState extends State<CoverImageNodeWidget> {
  CoverType get coverType => CoverType.fromString(
        widget.node.attributes[CoverBlockKeys.selectionType],
      );
  bool get hasIcon =>
      widget.node.attributes[CoverBlockKeys.iconSelection]?.isNotEmpty ?? false;
  bool get hasCover => coverType != CoverType.none;

  @override
  void initState() {
    super.initState();
    widget.node.addListener(_reload);
  }

  @override
  void dispose() {
    widget.node.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _calculateHeight(),
          child: _CoverImage(
            editorState: widget.editorState,
            node: widget.node,
            hasIcon: hasIcon,
            hasCover: hasCover,
            coverType: coverType,
            onCoverChanged: _saveCover,
          ),
        ),
        CoverToolbar(
          onCoverChanged: _saveCover,
          node: widget.node,
          editorState: widget.editorState,
          hasCover: hasCover,
          hasIcon: hasIcon,
        )
      ],
    );
  }

  double _calculateHeight() {
    double height = 0;
    if (hasCover) {
      height = kCoverHeight;
    }
    if (hasIcon) {
      height = kCoverHeight + 40; // half of height of icon widget
    }
    return height;
  }

  Future<void> _saveCover({(CoverType, String?)? cover, String? icon}) {
    final transaction = widget.editorState.transaction;
    final Map<String, dynamic> attributes = {
      CoverBlockKeys.selectionType:
          widget.node.attributes[CoverBlockKeys.selectionType],
      CoverBlockKeys.selection:
          widget.node.attributes[CoverBlockKeys.selection],
      CoverBlockKeys.iconSelection:
          widget.node.attributes[CoverBlockKeys.iconSelection]
    };
    if (cover != null) {
      attributes[CoverBlockKeys.selectionType] = cover.$1.toString();
      attributes[CoverBlockKeys.selection] = cover.$2;
    }
    if (icon != null) {
      attributes[CoverBlockKeys.iconSelection] = icon;
    }

    transaction.updateNode(widget.node, attributes);
    return widget.editorState.apply(transaction);
  }
}

class _CoverImage extends StatefulWidget {
  final Node node;
  final EditorState editorState;
  final bool hasIcon;
  final bool hasCover;
  final CoverType coverType;
  final Future<void> Function({(CoverType, String?) cover, String? icon})
      onCoverChanged;

  const _CoverImage({
    required this.editorState,
    required this.node,
    required this.hasIcon,
    required this.hasCover,
    required this.coverType,
    required this.onCoverChanged,
  });

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  bool isOverlayButtonsHidden = true;
  bool isPopoverOpen = false;

  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.hasCover)
          SizedBox(
            height: kCoverHeight,
            child: _buildCoverImage(context, widget.editorState),
          ),
        if (widget.hasIcon)
          Positioned(
            left: 80,
            bottom: 0,
            child: AppFlowyPopover(
              direction: PopoverDirection.bottomWithCenterAligned,
              controller: _popoverController,
              offset: const Offset(0, 8),
              constraints: BoxConstraints.loose(const Size(320, 380)),
              child: EmojiIconWidget(
                emoji: widget.node.attributes[CoverBlockKeys.iconSelection],
              ),
              popupBuilder: (BuildContext popoverContext) {
                return EmojiPopover(
                  node: widget.node,
                  showRemoveButton: widget.hasIcon,
                  removeIcon: () {
                    widget.onCoverChanged(icon: "");
                    _popoverController.close();
                  },
                  editorState: widget.editorState,
                  onEmojiChanged: (Emoji emoji) {
                    widget.onCoverChanged(icon: emoji.emoji);
                    _popoverController.close();
                  },
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildCoverImage(BuildContext context, EditorState editorState) {
    final Widget coverImage;
    switch (widget.coverType) {
      case CoverType.file:
        final imageFile =
            File(widget.node.attributes[CoverBlockKeys.selection]);
        if (!imageFile.existsSync()) {
          // reset cover state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCoverChanged(cover: (CoverType.none, null));
          });
          coverImage = const SizedBox.shrink();
          break;
        }
        coverImage = Image.file(
          imageFile,
          fit: BoxFit.cover,
        );
        break;
      case CoverType.asset:
        coverImage = Image.asset(
          widget.node.attributes[CoverBlockKeys.selection],
          fit: BoxFit.cover,
        );
        break;
      case CoverType.color:
        final hex = widget.node.attributes[CoverBlockKeys.selection] as String?;
        final color = hex?.toColor() ?? Colors.white;
        coverImage = Container(color: color);
        break;
      case CoverType.none:
        coverImage = const SizedBox.shrink();
        break;
    }

    return MouseRegion(
      onEnter: (event) => setOverlayButtonsHidden(false),
      onExit: (event) => setOverlayButtonsHidden(isPopoverOpen ? false : true),
      child: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: coverImage,
          ),
          if (!isOverlayButtonsHidden) _buildCoverOverlayButtons(context)
        ],
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
            offset: const Offset(0, 8),
            direction: PopoverDirection.bottomWithCenterAligned,
            constraints: BoxConstraints.loose(const Size(380, 450)),
            margin: EdgeInsets.zero,
            onClose: () => isPopoverOpen = false,
            child: RoundedTextButton(
              hoverColor: Theme.of(context).colorScheme.surface,
              textColor: Theme.of(context).colorScheme.tertiary,
              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              width: 120,
              height: 28,
              title: LocaleKeys.document_plugins_cover_changeCover.tr(),
            ),
            popupBuilder: (BuildContext popoverContext) {
              isPopoverOpen = true;
              return ChangeCoverPopover(
                node: widget.node,
                editorState: widget.editorState,
                onCoverChanged: (cover, selection) =>
                    widget.onCoverChanged(cover: (cover, selection)),
              );
            },
          ),
          const HSpace(10),
          FlowyIconButton(
            hoverColor: Theme.of(context).colorScheme.surface,
            fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            iconPadding: const EdgeInsets.all(5),
            width: 28,
            icon: svgWidget(
              'editor/delete',
              color: Theme.of(context).colorScheme.tertiary,
            ),
            onPressed: () {
              widget.onCoverChanged(cover: (CoverType.none, null));
            },
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
class CoverToolbar extends StatefulWidget {
  final Node node;
  final EditorState editorState;
  final bool hasCover;
  final bool hasIcon;
  final Future<void> Function({(CoverType, String?)? cover, String? icon})
      onCoverChanged;

  const CoverToolbar({
    required this.node,
    required this.editorState,
    required this.hasCover,
    required this.hasIcon,
    required this.onCoverChanged,
    super.key,
  });

  @override
  State<CoverToolbar> createState() => _CoverToolbarState();
}

class _CoverToolbarState extends State<CoverToolbar> {
  bool isHidden = true;
  bool isPopoverOpen = false;

  final PopoverController _poopoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setHidden(false);
      },
      onExit: (event) {
        if (!isPopoverOpen) {
          setHidden(true);
        }
      },
      opaque: false,
      child: Container(
        height: widget.hasCover || widget.hasIcon ? 35 : 50,
        alignment: Alignment.bottomLeft,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildRowChildren(),
          ),
        ),
      ),
    );
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
            cover: (CoverType.asset, builtInAssetImages.first),
          ),
          useIntrinsicWidth: true,
          leftIcon: const FlowySvg(name: 'editor/image'),
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
      children.add(
        AppFlowyPopover(
          onClose: () => isPopoverOpen = false,
          controller: _poopoverController,
          offset: const Offset(0, 8),
          direction: PopoverDirection.bottomWithCenterAligned,
          constraints: BoxConstraints.loose(const Size(320, 380)),
          child: FlowyButton(
            leftIconSize: const Size.square(18),
            useIntrinsicWidth: true,
            leftIcon: const Icon(
              Icons.emoji_emotions_outlined,
              size: 18,
            ),
            text: FlowyText.regular(
              LocaleKeys.document_plugins_cover_addIcon.tr(),
            ),
          ),
          popupBuilder: (BuildContext popoverContext) {
            isPopoverOpen = true;
            return EmojiPopover(
              showRemoveButton: widget.hasIcon,
              removeIcon: () => widget.onCoverChanged(icon: ""),
              node: widget.node,
              editorState: widget.editorState,
              onEmojiChanged: (Emoji emoji) {
                widget.onCoverChanged(icon: emoji.emoji);
                _poopoverController.close();
              },
            );
          },
        ),
      );
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
