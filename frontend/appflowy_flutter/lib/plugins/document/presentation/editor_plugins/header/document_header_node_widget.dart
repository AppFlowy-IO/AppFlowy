import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';

import 'cover_editor.dart';
import 'emoji_icon_widget.dart';
import 'emoji_popover.dart';

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
    required this.node,
    required this.editorState,
    super.key,
  });

  final Node node;
  final EditorState editorState;

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
  String get icon => widget.node.attributes[DocumentHeaderBlockKeys.icon];
  bool get hasIcon =>
      widget.node.attributes[DocumentHeaderBlockKeys.icon]?.isNotEmpty ?? false;
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
            left: 80,
            // if hasCover, there shouldn't be icons present so the icon can
            // be closer to the bottom.
            bottom:
                hasCover ? kToolbarHeight - kIconHeight / 2 : kToolbarHeight,
            child: DocumentIcon(
              editorState: widget.editorState,
              node: widget.node,
              icon: icon,
              onIconChanged: (icon) => _saveCover(icon: icon),
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
          widget.node.attributes[DocumentHeaderBlockKeys.icon]
    };
    if (cover != null) {
      attributes[DocumentHeaderBlockKeys.coverType] = cover.$1.toString();
      attributes[DocumentHeaderBlockKeys.coverDetails] = cover.$2;
    }
    if (icon != null) {
      attributes[DocumentHeaderBlockKeys.icon] = icon;
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
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setHidden(false),
      onExit: (event) {
        if (!isPopoverOpen) {
          setHidden(true);
        }
      },
      opaque: false,
      child: Container(
        alignment: Alignment.bottomLeft,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
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
      children.add(
        AppFlowyPopover(
          onClose: () => isPopoverOpen = false,
          controller: _popoverController,
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
              removeIcon: () {
                widget.onCoverChanged(icon: "");
                _popoverController.close();
              },
              node: widget.node,
              editorState: widget.editorState,
              onEmojiChanged: (Emoji emoji) {
                widget.onCoverChanged(icon: emoji.emoji);
                _popoverController.close();
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

  @override
  Widget build(BuildContext context) {
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
            if (!isOverlayButtonsHidden) _buildCoverOverlayButtons(context)
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    switch (widget.coverType) {
      case CoverType.file:
        final imageFile = File(widget.coverDetails ?? "");
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
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.surface,
      fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      iconPadding: const EdgeInsets.all(5),
      width: 28,
      icon: FlowySvg(
        FlowySvgs.delete_s,
        color: Theme.of(context).colorScheme.tertiary,
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
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithCenterAligned,
      controller: _popoverController,
      offset: const Offset(0, 8),
      constraints: BoxConstraints.loose(const Size(320, 380)),
      child: EmojiIconWidget(emoji: widget.icon),
      popupBuilder: (BuildContext popoverContext) {
        return EmojiPopover(
          node: widget.node,
          showRemoveButton: true,
          removeIcon: () {
            widget.onIconChanged("");
            _popoverController.close();
          },
          editorState: widget.editorState,
          onEmojiChanged: (Emoji emoji) {
            widget.onIconChanged(emoji.emoji);
            _popoverController.close();
          },
        );
      },
    );
  }
}
