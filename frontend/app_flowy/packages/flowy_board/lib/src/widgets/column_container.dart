import 'package:flutter/material.dart';

import '../rendering/board_overlay.dart';
import 'flex/reorder_flex.dart';
import 'board.dart';

class BoardColumnContainer extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final ScrollController? scrollController;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final BoardDataController boardDataController;
  final List<Widget> children;
  final EdgeInsets? padding;
  final Widget? background;
  final ReorderFlexConfig config;

  const BoardColumnContainer({
    required this.boardDataController,
    required this.onReorder,
    required this.children,
    this.onDragStarted,
    this.onDragEnded,
    this.header,
    this.footer,
    this.scrollController,
    this.padding,
    this.background,
    this.config = const ReorderFlexConfig(),
    Key? key,
  }) : super(key: key);

  @override
  State<BoardColumnContainer> createState() => _BoardColumnContainerState();
}

class _BoardColumnContainerState extends State<BoardColumnContainer> {
  final GlobalKey _columnContainerOverlayKey =
      GlobalKey(debugLabel: '$BoardColumnContainer overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          Widget reorderFlex = ReorderFlex(
            key: widget.key,
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: (index) {},
            onReorder: ((fromIndex, toIndex) {}),
            onDragEnded: () {},
            dataSource: widget.boardDataController,
            direction: Axis.horizontal,
            children: widget.children,
          );

          if (widget.padding != null) {
            reorderFlex = Padding(
              padding: widget.padding!,
              child: reorderFlex,
            );
          }

          return Expanded(
              child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Container(
                color: Colors.red,
              ),
              reorderFlex
            ],
          ));
        },
        opaque: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BoardOverlay(
      key: _columnContainerOverlayKey,
      initialEntries: [_overlayEntry],
    );
  }
}
