import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/cover/change_cover_popover.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/close_button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kCoverType = 'cover';
const String kCoverSelectionTypeAttribute = 'cover_selection_type';
const String kCoverSelectionAttribute = 'cover_selection';

enum CoverSelectionType {
  color,
  file,
  asset,
}

SelectionMenuItem coverMenuItem = SelectionMenuItem.node(
  name: 'Cover',
  iconData: Icons.image,
  keywords: ['cover'],
  nodeBuilder: (editorState) {
    final node = Node(type: kCoverType);
    node.insert(TextNode.empty());
    return node;
  },
  replace: (_, textNode) => textNode.toPlainText().isEmpty,
  updateSelection: (_, path, __, ___) {
    return Selection.single(path: [...path, 0], startOffset: 0);
  },
);

class CoverNodeWidgetBuilder implements NodeWidgetBuilder {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    // TODO: implement build
    return _CoverImageNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  // TODO: implement nodeValidator
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
  State<_CoverImageNodeWidget> createState() => __CoverImageNodeWidgetState();
}

class __CoverImageNodeWidgetState extends State<_CoverImageNodeWidget>
    with Selectable {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;
  final _popoverController = PopoverController();
  late PopoverMutex popoverMutex;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    popoverMutex = PopoverMutex();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        _buildCover(screenSize),
        Positioned(
          bottom: 12,
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFlowyPopover(
                mutex: popoverMutex,
                offset: Offset(-125, 10),
                controller: _popoverController,
                direction: PopoverDirection.bottomWithCenterAligned,
                triggerActions: PopoverTriggerFlags.none,
                constraints: BoxConstraints.loose(const Size(380, 450)),
                margin: EdgeInsets.zero,
                child: RoundedTextButton(
                  onPressed: () {
                    _popoverController.show();
                  },
                  hoverColor: Theme.of(context).colorScheme.surface,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  fillColor:
                      Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  width: 120,
                  height: 28,
                  // fontSize: 12,
                  title: LocaleKeys.cover_changeCover.tr(),
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
                          kCoverSelectionAttribute: value
                        },
                      );
                      await widget.editorState.apply(transaction);
                      setState(() {});
                    },
                  );
                },
              ),
              const SizedBox(width: 10),
              FlowyIconButton(
                fillColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                hoverColor: Theme.of(context).colorScheme.surface,
                iconPadding: const EdgeInsets.all(5),
                width: 28,
                icon: svgWidget(
                  "editor/delete",
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () async {
                  final transaction = widget.editorState.transaction;

                  transaction.deleteNode(
                    widget.node,
                  );
                  await widget.editorState.apply(transaction);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  _buildCover(screenSize) {
    if (widget.node.attributes[kCoverSelectionTypeAttribute] ==
        CoverSelectionType.file.toString()) {
      return Positioned(
        child: ClipRRect(
          borderRadius: Corners.s6Border,
          child: Image.file(
            File(widget.node.attributes[kCoverSelectionAttribute]),
            height: 250,
            width: screenSize.width,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    if (widget.node.attributes[kCoverSelectionTypeAttribute] ==
        CoverSelectionType.color.toString()) {
      return Positioned(
        child: Container(
          height: 250,
          width: screenSize.width,
          decoration: BoxDecoration(
              color: Color(int.tryParse(
                      widget.node.attributes[kCoverSelectionAttribute]) ??
                  0xFFFFFFFF),
              borderRadius: Corners.s6Border),
          alignment: Alignment.center,
        ),
      );
    }
    if (widget.node.attributes[kCoverSelectionTypeAttribute] ==
        CoverSelectionType.asset.toString()) {
      return Positioned(
        child: ClipRRect(
          borderRadius: Corners.s6Border,
          child: Image.asset(
            widget.node.attributes[kCoverSelectionAttribute],
            height: 250,
            width: screenSize.width,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Positioned(
        child: ClipRRect(
          borderRadius: Corners.s6Border,
          child: Image.asset(
            "assets/images/app_flowy_abstract_cover_2.jpg",
            height: 250,
            width: screenSize.width,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  List<Rect> getRectsInSelection(Selection selection) =>
      [Offset.zero & _renderBox.size];

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    // TODO: implement dispatchSelectionEvent
    throw UnimplementedError();
  }

  @override
  SelectedContent? getSelectedContent() {
    // TODO: implement getSelectedContent
    throw UnimplementedError();
  }

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) {
    // TODO: implement getTransformTo
    throw UnimplementedError();
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    // TODO: implement pushHandleLayers
  }

  @override
  void removeListener(VoidCallback listener) {
    // TODO: implement removeListener
  }

  @override
  // TODO: implement size
  Size get size => throw UnimplementedError();

  @override
  // TODO: implement value
  SelectionGeometry get value => throw UnimplementedError();
}
