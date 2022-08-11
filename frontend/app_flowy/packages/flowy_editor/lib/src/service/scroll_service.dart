import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

abstract class FlowyScrollService {
  double get dy;

  void scrollTo(double dy);

  void enable();
  void disable();
}

class FlowyScroll extends StatefulWidget {
  const FlowyScroll({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  State<FlowyScroll> createState() => _FlowyScrollState();
}

class _FlowyScrollState extends State<FlowyScroll>
    implements FlowyScrollService {
  final _scrollController = ScrollController();
  final _scrollViewKey = GlobalKey();

  bool _scrollEnabled = true;

  @override
  double get dy => _scrollController.position.pixels;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: SingleChildScrollView(
        key: _scrollViewKey,
        physics: const NeverScrollableScrollPhysics(),
        controller: _scrollController,
        child: widget.child,
      ),
    );
  }

  @override
  void scrollTo(double dy) {
    _scrollController.position.jumpTo(
      dy.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  @override
  void disable() {
    _scrollEnabled = false;
    debugPrint('[scroll] $_scrollEnabled');
  }

  @override
  void enable() {
    _scrollEnabled = true;
    debugPrint('[scroll] $_scrollEnabled');
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _scrollEnabled) {
      final dy = (_scrollController.position.pixels + event.scrollDelta.dy);
      scrollTo(dy);
    }
  }
}
