import 'package:flutter/material.dart';

import 'styled_list.dart';
import 'styled_scroll_bar.dart';

class StyledSingleChildScrollView extends StatefulWidget {
  final double? contentSize;
  final Axis axis;
  final Color? trackColor;
  final Color? handleColor;
  final ScrollController? controller;

  final Widget? child;

  const StyledSingleChildScrollView({
    Key? key,
    @required this.child,
    this.contentSize,
    this.axis = Axis.vertical,
    this.trackColor,
    this.handleColor,
    this.controller,
  }) : super(key: key);

  @override
  _StyledSingleChildScrollViewState createState() => _StyledSingleChildScrollViewState();
}

class _StyledSingleChildScrollViewState extends State<StyledSingleChildScrollView> {
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
      barSize: 12,
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
  final double? contentSize;
  final Axis axis;
  final Color? trackColor;
  final Color? handleColor;
  final ScrollController? controller;
  final List<Widget> slivers;

  const StyledCustomScrollView({
    Key? key,
    this.contentSize,
    this.axis = Axis.vertical,
    this.trackColor,
    this.handleColor,
    this.controller,
    this.slivers = const <Widget>[],
  }) : super(key: key);

  @override
  _StyledCustomScrollViewState createState() => _StyledCustomScrollViewState();
}

class _StyledCustomScrollViewState extends State<StyledCustomScrollView> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = widget.controller ?? ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
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
    return ScrollbarListStack(
      contentSize: widget.contentSize,
      axis: widget.axis,
      controller: scrollController,
      barSize: 12,
      trackColor: widget.trackColor,
      handleColor: widget.handleColor,
      child: CustomScrollView(
        scrollDirection: widget.axis,
        physics: StyledScrollPhysics(),
        controller: scrollController,
        slivers: widget.slivers,
      ),
    );
  }
}
