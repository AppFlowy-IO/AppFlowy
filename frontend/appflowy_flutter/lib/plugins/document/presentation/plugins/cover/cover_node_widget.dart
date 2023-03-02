import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/cover/change_cover_popover.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
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
  final popoverController = PopoverController();
  CoverSelectionType get selectionType => CoverSelectionType.fromString(
        widget.node.attributes[kCoverSelectionTypeAttribute],
      );

  @override
  Widget build(BuildContext context) {
    if (selectionType == CoverSelectionType.initial) {
      return _buildAddCoverButton();
    }
    return Stack(
      children: [
        _buildCoverImage(context),
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
            triggerActions: PopoverTriggerFlags.none,
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
                onCoverChanged: (type, value) async {
                  final transaction = widget.editorState.transaction;
                  transaction.updateNode(
                    widget.node,
                    {
                      kCoverSelectionTypeAttribute: type.toString(),
                      kCoverSelectionAttribute: value,
                    },
                  );
                  await widget.editorState.apply(transaction);
                },
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
              "editor/delete",
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              final transaction = widget.editorState.transaction;
              transaction.updateNode(
                widget.node,
                {
                  kCoverSelectionTypeAttribute:
                      CoverSelectionType.initial.toString(),
                  kCoverSelectionAttribute: null,
                },
              );
              await widget.editorState.apply(transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddCoverButton() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 5),
      child: FlowyButton(
        leftIconSize: const Size.square(18),
        onTap: () async {
          final transaction = widget.editorState.transaction;
          transaction.updateNode(
            widget.node,
            {
              kCoverSelectionTypeAttribute: CoverSelectionType.asset.toString(),
              kCoverSelectionAttribute:
                  "assets/images/app_flowy_abstract_cover_2.jpg"
            },
          );
          await widget.editorState.apply(transaction);
        },
        useIntrinsicWidth: true,
        leftIcon: svgWidget(
          "editor/image",
          color: Theme.of(context).colorScheme.onSurface,
        ),
        text: FlowyText.regular(
          LocaleKeys.document_plugins_cover_addCover.tr(),
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
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
            color: Color(int.tryParse(
                    widget.node.attributes[kCoverSelectionAttribute]) ??
                0xFFFFFFFF),
            borderRadius: Corners.s6Border,
          ),
          alignment: Alignment.center,
        );
        break;
      case CoverSelectionType.initial:
        coverImage = const SizedBox(); // just an empty sizebox
        break;
    }
    return UnconstrainedBox(
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        height: height,
        width: screenSize.width,
        child: coverImage,
      ),
    );
  }
}
