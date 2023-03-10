import 'package:flutter/material.dart';

import 'styled_list.dart';
import 'styled_scroll_bar.dart';

class StyledSingleChildScrollView extends StatefulWidget {
  final double? contentSize;
  final Axis axis;
  final Color? trackColor;
  final Color? handleColor;
  final ScrollController? controller;
  final EdgeInsets? scrollbarPadding;
  final double barSize;

  final Widget? child;

  const StyledSingleChildScrollView({
    Key? key,
    @required this.child,
    this.contentSize,
    this.axis = Axis.vertical,
    this.trackColor,
    this.handleColor,
    this.controller,
    this.scrollbarPadding,
    this.barSize = 12,
  }) : super(key: key);

  @override
  State<StyledSingleChildScrollView> createState() =>
      StyledSingleChildScrollViewState();
}

class StyledSingleChildScrollViewState
    extends State<StyledSingleChildScrollView> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = widget.controller ?? ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    // scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StyledSingleChildScrollView oldWidget) {
    if (oldWidget.child != widget.child) {
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarListStack(
      contentSize: widget.contentSize,
      axis: widget.axis,
      controller: scrollController,
      scrollbarPadding: widget.scrollbarPadding,
      barSize: widget.barSize,
      trackColor: widget.trackColor,
      handleColor: widget.handleColor,
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
  final Axis axis;
  final Color? trackColor;
  final Color? handleColor;
  final ScrollController? verticalController;
  final List<Widget> slivers;
  final double barSize;

  const StyledCustomScrollView({
    Key? key,
    this.axis = Axis.vertical,
    this.trackColor,
    this.handleColor,
    this.verticalController,
    this.slivers = const <Widget>[],
    this.barSize = 12,
  }) : super(key: key);

  @override
  StyledCustomScrollViewState createState() => StyledCustomScrollViewState();
}

class StyledCustomScrollViewState extends State<StyledCustomScrollView> {
  late ScrollController controller;

  @override
  void initState() {
    controller = widget.verticalController ?? ScrollController();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(StyledCustomScrollView oldWidget) {
    if (oldWidget.slivers != widget.slivers) {
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

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
