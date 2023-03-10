import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/cover/change_cover_popover.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';

const String kCoverType = 'cover';
const String kCoverSelectionTypeAttribute = 'cover_selection_type';
const String kCoverSelectionAttribute = 'cover_selection';

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
    return _CoverImageNodeWidget(
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

class _CoverImageNodeWidget extends StatefulWidget {
  const _CoverImageNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_CoverImageNodeWidget> createState() => _CoverImageNodeWidgetState();
}

class _CoverImageNodeWidgetState extends State<_CoverImageNodeWidget> {
  CoverSelectionType get selectionType => CoverSelectionType.fromString(
        widget.node.attributes[kCoverSelectionTypeAttribute],
      );

  @override
  Widget build(BuildContext context) {
    if (selectionType == CoverSelectionType.initial) {
      return _AddCoverButton(
        onTap: () {
          _insertCover(CoverSelectionType.asset, builtInAssetImages.first);
        },
      );
    } else {
      return _CoverImage(
        editorState: widget.editorState,
        node: widget.node,
        onCoverChanged: (type, value) {
          _insertCover(type, value);
        },
      );
    }
  }

  Future<void> _insertCover(CoverSelectionType type, dynamic cover) async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      kCoverSelectionTypeAttribute: type.toString(),
      kCoverSelectionAttribute: cover,
    });
    return widget.editorState.apply(transaction);
  }
}

class _AddCoverButton extends StatefulWidget {
  const _AddCoverButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_AddCoverButton> createState() => _AddCoverButtonState();
}

class _AddCoverButtonState extends State<_AddCoverButton> {
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setHidden(false);
      },
      onExit: (event) {
        setHidden(true);
      },
      child: Container(
        height: 50.0,
        width: double.infinity,
        padding: const EdgeInsets.only(top: 20, bottom: 5),
        // color: Colors.red,
        child: isHidden
            ? const SizedBox()
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Add Cover Button.
                  FlowyButton(
                    leftIconSize: const Size.square(18),
                    onTap: widget.onTap,
                    useIntrinsicWidth: true,
                    leftIcon: svgWidget(
                      'editor/image',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    text: FlowyText.regular(
                      LocaleKeys.document_plugins_cover_addCover.tr(),
                    ),
                  )
                  // Add Icon Button.
                  // ...
                ],
              ),
      ),
    );
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
        widget.node.attributes[kCoverSelectionTypeAttribute],
      );
  Color get color =>
      Color(int.tryParse(widget.node.attributes[kCoverSelectionAttribute]) ??
          0xFFFFFFFF);

  bool isOverlayButtonsHidden = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildCoverImage(context, widget.editorState),
        _buildCoverOverlayButtons(context),
      ],
    );
  }

  Widget _buildCoverOverlayButtons(BuildContext context) {
    return Positioned(
      bottom: 22,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFlowyPopover(
            offset: const Offset(-125, 10),
            controller: popoverController,
            direction: PopoverDirection.bottomWithCenterAligned,
            constraints: BoxConstraints.loose(const Size(380, 450)),
            margin: EdgeInsets.zero,
            child: RoundedTextButton(
              onPressed: () {
                popoverController.show();
              },
              hoverColor: Theme.of(context).colorScheme.surface,
              textColor: Theme.of(context).colorScheme.onSurface,
              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              width: 120,
              height: 28,
              title: LocaleKeys.document_plugins_cover_changeCover.tr(),
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
          FlowyIconButton(
            fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            hoverColor: Theme.of(context).colorScheme.surface,
            iconPadding: const EdgeInsets.all(5),
            width: 28,
            icon: svgWidget(
              'editor/delete',
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              widget.onCoverChanged(CoverSelectionType.initial, null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context, EditorState editorState) {
    final screenSize = MediaQuery.of(context).size;
    const height = 200.0;
    final Widget coverImage;
    switch (selectionType) {
      case CoverSelectionType.file:
        coverImage = Image.file(
          File(widget.node.attributes[kCoverSelectionAttribute]),
          fit: BoxFit.cover,
        );
        break;
      case CoverSelectionType.asset:
        coverImage = Image.asset(
          widget.node.attributes[kCoverSelectionAttribute],
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
        coverImage = const SizedBox(); // just an empty sizebox
        break;
    }
//OverflowBox needs to be wraped by a widget with constraints(or from its parent) first,otherwise it will occur an erorr
    return SizedBox(
      height: height,
      child: OverflowBox(
        maxWidth:
            screenSize.width + editorState.editorStyle.padding!.horizontal,
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          height: double.infinity,
          width: double.infinity,
          child: coverImage,
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
