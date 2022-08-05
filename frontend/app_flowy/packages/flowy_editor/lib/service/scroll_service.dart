import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

mixin FlowyScrollService<T extends StatefulWidget> on State<T> {
  double get dy;

  void scrollTo(double dy);

  RenderObject? scrollRenderObject();
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

class _FlowyScrollState extends State<FlowyScroll> with FlowyScrollService {
  final _scrollController = ScrollController();
  final _scrollViewKey = GlobalKey();

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

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final dy = (_scrollController.position.pixels + event.scrollDelta.dy);
      scrollTo(dy);
    }
  }

  @override
  RenderObject? scrollRenderObject() {
    return _scrollViewKey.currentContext?.findRenderObject();
  }
}
