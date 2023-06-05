import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/change_cover_popover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/emoji_popover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide FlowySvg;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';

class CoverBlockKeys {
  const CoverBlockKeys._();

  static const String selectionType = 'cover_selection_type';
  static const String selection = 'cover_selection';
  static const String iconSelection = 'selected_icon';
}

enum CoverSelectionType {
  initial,
  color,
  file,
  asset;

  static CoverSelectionType fromString(String? value) {
    if (value == null) {
      return CoverSelectionType.initial;
    }
    return CoverSelectionType.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => CoverSelectionType.initial,
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
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}

class CoverImageNodeWidget extends StatefulWidget {
  const CoverImageNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<CoverImageNodeWidget> createState() => _CoverImageNodeWidgetState();
}

class _CoverImageNodeWidgetState extends State<CoverImageNodeWidget> {
  CoverSelectionType get selectionType => CoverSelectionType.fromString(
        widget.node.attributes[CoverBlockKeys.selectionType],
      );

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

  void _reload() {
    setState(() {});
  }

  PopoverController iconPopoverController = PopoverController();
  @override
  Widget build(BuildContext context) {
    return _CoverImage(
      editorState: widget.editorState,
      node: widget.node,
      onCoverChanged: (type, value) {
        _insertCover(type, value);
      },
    );
  }

  Future<void> _insertCover(CoverSelectionType type, dynamic cover) async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      CoverBlockKeys.selectionType: type.toString(),
      CoverBlockKeys.selection: cover,
      CoverBlockKeys.iconSelection:
          widget.node.attributes[CoverBlockKeys.iconSelection]
    });
    return widget.editorState.apply(transaction);
  }
}

class _AddCoverButton extends StatefulWidget {
  final Node node;
  final EditorState editorState;
  final bool hasIcon;
  final CoverSelectionType selectionType;

  final PopoverController iconPopoverController;
  const _AddCoverButton({
    required this.onTap,
    required this.node,
    required this.editorState,
    required this.hasIcon,
    required this.selectionType,
    required this.iconPopoverController,
  });

  final VoidCallback onTap;

  @override
  State<_AddCoverButton> createState() => _AddCoverButtonState();
}

bool isPopoverOpen = false;

class _AddCoverButtonState extends State<_AddCoverButton> {
  bool isHidden = true;
  PopoverMutex mutex = PopoverMutex();
  bool isPopoverOpen = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setHidden(false);
      },
      onExit: (event) {
        setHidden(isPopoverOpen ? false : true);
      },
      opaque: false,
      child: Container(
        height: widget.hasIcon ? 180 : 50.0,
        alignment: Alignment.bottomLeft,
        width: double.infinity,
        padding: EdgeInsets.only(
          left: EditorStyleCustomizer.horizontalPadding + 30,
          top: 20,
          bottom: 5,
        ),
        child: isHidden
            ? Container()
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Add Cover Button.
                  widget.selectionType != CoverSelectionType.initial
                      ? Container()
                      : FlowyButton(
                          key: UniqueKey(),
                          leftIconSize: const Size.square(18),
                          onTap: widget.onTap,
                          useIntrinsicWidth: true,
                          leftIcon: const FlowySvg(name: 'editor/image'),
                          text: FlowyText.regular(
                            LocaleKeys.document_plugins_cover_addCover.tr(),
                          ),
                        ),
                  // Add Icon Button.
                  widget.hasIcon
                      ? FlowyButton(
                          leftIconSize: const Size.square(18),
                          onTap: () {
                            _removeIcon();
                          },
                          useIntrinsicWidth: true,
                          leftIcon: const Icon(
                            Icons.emoji_emotions_outlined,
                            size: 18,
                          ),
                          text: FlowyText.regular(
                            LocaleKeys.document_plugins_cover_removeIcon.tr(),
                          ),
                        )
                      : AppFlowyPopover(
                          mutex: mutex,
                          asBarrier: true,
                          onClose: () {
                            isPopoverOpen = false;
                            setHidden(true);
                          },
                          offset: const Offset(120, 10),
                          controller: widget.iconPopoverController,
                          direction: PopoverDirection.bottomWithCenterAligned,
                          constraints:
                              BoxConstraints.loose(const Size(320, 380)),
                          margin: EdgeInsets.zero,
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
                              removeIcon: _removeIcon,
                              node: widget.node,
                              editorState: widget.editorState,
                              onEmojiChanged: (Emoji emoji) {
                                _insertIcon(emoji);
                                widget.iconPopoverController.close();
                              },
                            );
                          },
                        )
                ],
              ),
      ),
    );
  }

  Future<void> _insertIcon(Emoji emoji) async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      CoverBlockKeys.selectionType:
          widget.node.attributes[CoverBlockKeys.selectionType],
      CoverBlockKeys.selection:
          widget.node.attributes[CoverBlockKeys.selection],
      CoverBlockKeys.iconSelection: emoji.emoji,
    });
    return widget.editorState.apply(transaction);
  }

  Future<void> _removeIcon() async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      CoverBlockKeys.iconSelection: "",
      CoverBlockKeys.selectionType:
          widget.node.attributes[CoverBlockKeys.selectionType],
      CoverBlockKeys.selection:
          widget.node.attributes[CoverBlockKeys.selection],
    });
    return widget.editorState.apply(transaction);
  }

  void setHidden(bool value) {
    if (isHidden == value) return;
    setState(() {
      isHidden = value;
    });
  }
}

class _CoverImage extends StatefulWidget {
  const _CoverImage({
    required this.editorState,
    required this.node,
    required this.onCoverChanged,
  });

  final Node node;
  final EditorState editorState;
  final Function(
    CoverSelectionType selectionType,
    dynamic selection,
  ) onCoverChanged;
  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  final popoverController = PopoverController();

  CoverSelectionType get selectionType => CoverSelectionType.fromString(
        widget.node.attributes[CoverBlockKeys.selectionType],
      );
  Color get color {
    final hex = widget.node.attributes[CoverBlockKeys.selection] as String?;
    return hex?.toColor() ?? Colors.white;
  }

  bool get hasIcon =>
      widget.node.attributes[CoverBlockKeys.iconSelection] == null
          ? false
          : widget.node.attributes[CoverBlockKeys.iconSelection].isNotEmpty;
  bool isOverlayButtonsHidden = true;
  PopoverController iconPopoverController = PopoverController();
  bool get hasCover =>
      selectionType == CoverSelectionType.initial ? false : true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(
          alignment: Alignment.topCenter,
          height: !hasCover
              ? 0
              : hasIcon
                  ? 320
                  : 280,
          child: _buildCoverImage(context, widget.editorState),
        ),
        hasIcon
            ? Positioned(
                left: EditorStyleCustomizer.horizontalPadding + 30,
                bottom: !hasCover ? 30 : 40,
                child: AppFlowyPopover(
                  offset: const Offset(100, 0),
                  controller: iconPopoverController,
                  direction: PopoverDirection.bottomWithCenterAligned,
                  constraints: BoxConstraints.loose(const Size(320, 380)),
                  margin: EdgeInsets.zero,
                  child: EmojiIconWidget(
                    emoji: widget.node.attributes[CoverBlockKeys.iconSelection],
                  ),
                  popupBuilder: (BuildContext popoverContext) {
                    return EmojiPopover(
                      node: widget.node,
                      showRemoveButton: hasIcon,
                      removeIcon: _removeIcon,
                      editorState: widget.editorState,
                      onEmojiChanged: (Emoji emoji) {
                        _insertIcon(emoji);
                        iconPopoverController.close();
                      },
                    );
                  },
                ),
              )
            : Container(),
        hasIcon && selectionType != CoverSelectionType.initial
            ? Container()
            : _AddCoverButton(
                onTap: () {
                  _insertCover(
                    CoverSelectionType.asset,
                    builtInAssetImages.first,
                  );
                },
                node: widget.node,
                editorState: widget.editorState,
                hasIcon: hasIcon,
                selectionType: selectionType,
                iconPopoverController: iconPopoverController,
              ),
      ],
    );
  }

  Future<void> _insertCover(CoverSelectionType type, dynamic cover) async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      CoverBlockKeys.selectionType: type.toString(),
      CoverBlockKeys.selection: cover,
      CoverBlockKeys.iconSelection:
          widget.node.attributes[CoverBlockKeys.iconSelection]
    });
    return widget.editorState.apply(transaction);
  }

  Future<void> _insertIcon(Emoji emoji) async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      CoverBlockKeys.selectionType:
          widget.node.attributes[CoverBlockKeys.selectionType],
      CoverBlockKeys.selection:
          widget.node.attributes[CoverBlockKeys.selection],
      CoverBlockKeys.iconSelection: emoji.emoji,
    });
    return widget.editorState.apply(transaction);
  }

  Future<void> _removeIcon() async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      CoverBlockKeys.iconSelection: "",
      CoverBlockKeys.selectionType:
          widget.node.attributes[CoverBlockKeys.selectionType],
      CoverBlockKeys.selection:
          widget.node.attributes[CoverBlockKeys.selection],
    });
    return widget.editorState.apply(transaction);
  }

  Widget _buildCoverOverlayButtons(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: EditorStyleCustomizer.horizontalPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFlowyPopover(
            onClose: () {
              setOverlayButtonsHidden(true);
            },
            offset: const Offset(-125, 10),
            controller: popoverController,
            direction: PopoverDirection.bottomWithCenterAligned,
            constraints: BoxConstraints.loose(const Size(380, 450)),
            margin: EdgeInsets.zero,
            child: Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: !isOverlayButtonsHidden,
              child: RoundedTextButton(
                onPressed: () {
                  popoverController.show();
                  setOverlayButtonsHidden(true);
                },
                hoverColor: Theme.of(context).colorScheme.surface,
                textColor: Theme.of(context).colorScheme.tertiary,
                fillColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.5),
                width: 120,
                height: 28,
                title: LocaleKeys.document_plugins_cover_changeCover.tr(),
              ),
            ),
            popupBuilder: (BuildContext popoverContext) {
              return ChangeCoverPopover(
                node: widget.node,
                editorState: widget.editorState,
                onCoverChanged: widget.onCoverChanged,
              );
            },
          ),
          const SizedBox(width: 10),
          Visibility(
            maintainAnimation: true,
            maintainSize: true,
            maintainState: true,
            visible: !isOverlayButtonsHidden,
            child: FlowyIconButton(
              hoverColor: Theme.of(context).colorScheme.surface,
              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              iconPadding: const EdgeInsets.all(5),
              width: 28,
              icon: svgWidget(
                'editor/delete',
                color: Theme.of(context).colorScheme.tertiary,
              ),
              onPressed: () {
                widget.onCoverChanged(CoverSelectionType.initial, null);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context, EditorState editorState) {
    const height = 250.0;
    final Widget coverImage;
    switch (selectionType) {
      case CoverSelectionType.file:
        final imageFile =
            File(widget.node.attributes[CoverBlockKeys.selection]);
        if (!imageFile.existsSync()) {
          // reset cover state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCoverChanged(CoverSelectionType.initial, null);
          });
          coverImage = const SizedBox();
          break;
        }
        coverImage = Image.file(
          imageFile,
          fit: BoxFit.cover,
        );
        break;
      case CoverSelectionType.asset:
        coverImage = Image.asset(
          widget.node.attributes[CoverBlockKeys.selection],
          fit: BoxFit.cover,
        );
        break;
      case CoverSelectionType.color:
        coverImage = Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: Corners.s6Border,
          ),
          alignment: Alignment.center,
        );
        break;
      case CoverSelectionType.initial:
        coverImage = const SizedBox();
        break;
    }
// OverflowBox needs to be wraped by a widget with constraints(or from its parent) first,otherwise it will occur an error
    return MouseRegion(
      onEnter: (event) {
        setOverlayButtonsHidden(false);
      },
      onExit: (event) {
        setOverlayButtonsHidden(true);
      },
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              height: double.infinity,
              width: double.infinity,
              child: coverImage,
            ),
            hasCover
                ? _buildCoverOverlayButtons(context)
                : const SizedBox.shrink()
          ],
        ),
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
