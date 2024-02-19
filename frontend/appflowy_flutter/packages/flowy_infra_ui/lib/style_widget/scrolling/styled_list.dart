import 'package:flutter/material.dart';

import 'styled_scroll_bar.dart';

class StyledScrollPhysics extends AlwaysScrollableScrollPhysics {}

/// Core ListView for the app.
/// Wraps a [ScrollbarListStack] + [ListView.builder] and assigns the 'Styled' scroll physics for the app
/// Exposes a controller so other widgets can manipulate the list
class StyledListView extends StatefulWidget {
  final double? itemExtent;
  final int? itemCount;
  final Axis axis;
  final EdgeInsets? padding;
  final EdgeInsets? scrollbarPadding;
  final double? barSize;

  final IndexedWidgetBuilder itemBuilder;

  StyledListView({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.itemExtent,
    this.axis = Axis.vertical,
    this.padding,
    this.barSize,
    this.scrollbarPadding,
  }) {
    assert(itemExtent != 0, 'Item extent should never be 0, null is ok.');
  }

  @override
  StyledListViewState createState() => StyledListViewState();
}

/// State is public so this can easily be controlled externally
class StyledListViewState extends State<StyledListView> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StyledListView oldWidget) {
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.itemExtent != widget.itemExtent) {
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final contentSize = (widget.itemCount ?? 0.0) * (widget.itemExtent ?? 00.0);
    Widget listContent = ScrollbarListStack(
      contentSize: contentSize,
      axis: widget.axis,
      controller: scrollController,
      barSize: widget.barSize ?? 8,
      scrollbarPadding: widget.scrollbarPadding,
      child: ListView.builder(
        padding: widget.padding,
        scrollDirection: widget.axis,
        physics: StyledScrollPhysics(),
        controller: scrollController,
        itemExtent: widget.itemExtent,
        itemCount: widget.itemCount,
        itemBuilder: (c, i) => widget.itemBuilder(c, i),
      ),
    );
    return listContent;
  }
}
