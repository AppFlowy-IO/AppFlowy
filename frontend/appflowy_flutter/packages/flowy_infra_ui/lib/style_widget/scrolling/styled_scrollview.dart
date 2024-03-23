import 'package:flutter/material.dart';

import 'styled_list.dart';
import 'styled_scroll_bar.dart';

class StyledSingleChildScrollView extends StatefulWidget {
  const StyledSingleChildScrollView({
    super.key,
    required this.child,
    this.contentSize,
    this.axis = Axis.vertical,
    this.trackColor,
    this.handleColor,
    this.controller,
    this.scrollbarPadding,
    this.barSize = 8,
    this.autoHideScrollbar = true,
    this.includeInsets = true,
  });

  final Widget? child;
  final double? contentSize;
  final Axis axis;
  final Color? trackColor;
  final Color? handleColor;
  final ScrollController? controller;
  final EdgeInsets? scrollbarPadding;
  final double barSize;
  final bool autoHideScrollbar;
  final bool includeInsets;

  @override
  State<StyledSingleChildScrollView> createState() =>
      StyledSingleChildScrollViewState();
}

class StyledSingleChildScrollViewState
    extends State<StyledSingleChildScrollView> {
  late final ScrollController scrollController =
      widget.controller ?? ScrollController();

  @override
  void dispose() {
    if (widget.controller == null) {
      scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarListStack(
      autoHideScrollbar: widget.autoHideScrollbar,
      contentSize: widget.contentSize,
      axis: widget.axis,
      controller: scrollController,
      scrollbarPadding: widget.scrollbarPadding,
      barSize: widget.barSize,
      trackColor: widget.trackColor,
      handleColor: widget.handleColor,
      includeInsets: widget.includeInsets,
      child: SingleChildScrollView(
        scrollDirection: widget.axis,
        physics: StyledScrollPhysics(),
        controller: scrollController,
        child: widget.child,
      ),
    );
  }
}

class StyledCustomScrollView extends StatefulWidget {
  const StyledCustomScrollView({
    super.key,
    this.axis = Axis.vertical,
    this.trackColor,
    this.handleColor,
    this.verticalController,
    this.slivers = const <Widget>[],
    this.barSize = 8,
  });

  final Axis axis;
  final Color? trackColor;
  final Color? handleColor;
  final ScrollController? verticalController;
  final List<Widget> slivers;
  final double barSize;

  @override
  StyledCustomScrollViewState createState() => StyledCustomScrollViewState();
}

class StyledCustomScrollViewState extends State<StyledCustomScrollView> {
  late final ScrollController controller =
      widget.verticalController ?? ScrollController();

  @override
  Widget build(BuildContext context) {
    var child = ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: CustomScrollView(
        scrollDirection: widget.axis,
        physics: StyledScrollPhysics(),
        controller: controller,
        slivers: widget.slivers,
      ),
    );

    return ScrollbarListStack(
      axis: widget.axis,
      controller: controller,
      barSize: widget.barSize,
      trackColor: widget.trackColor,
      handleColor: widget.handleColor,
      child: child,
    );
  }
}
