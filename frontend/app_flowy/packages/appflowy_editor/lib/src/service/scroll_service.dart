import 'package:appflowy_editor/src/infra/log.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';

/// [AppFlowyScrollService] is responsible for processing document scrolling.
///
/// Usually, this service can be obtained by the following code.
/// ```dart
/// final keyboardService = editorState.service.scrollService;
/// ```
///
abstract class AppFlowyScrollService {
  /// Returns the offset of the current document on the vertical axis.
  double get dy;

  /// Returns the height of the current document.
  double? get onePageHeight;

  /// Returns the number of pages in the current document.
  int? get page;

  /// Returns the maximum scroll height on the vertical axis.
  double get maxScrollExtent;

  /// Returns the minimum scroll height on the vertical axis.
  double get minScrollExtent;

  /// Scrolls to the specified position.
  ///
  /// This function will filter illegal values.
  /// Only within the range of minScrollExtent and maxScrollExtent are legal values.
  void scrollTo(double dy);

  /// Enables scroll service.
  void enable();

  /// Disables scroll service.
  ///
  /// In some cases, you can disable scroll service of flowy_editor
  ///  when your custom component appears,
  ///
  /// But you need to call the `enable` function to restore after exiting
  ///   your custom component, otherwise the scroll service will fails.
  void disable();
}

class AppFlowyScroll extends StatefulWidget {
  const AppFlowyScroll({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  State<AppFlowyScroll> createState() => _AppFlowyScrollState();
}

class _AppFlowyScrollState extends State<AppFlowyScroll>
    implements AppFlowyScrollService {
  final _scrollController = ScrollController();
  final _scrollViewKey = GlobalKey();

  bool _scrollEnabled = true;

  @override
  double get dy => _scrollController.position.pixels;

  @override
  double? get onePageHeight {
    final renderBox = context.findRenderObject()?.unwrapOrNull<RenderBox>();
    return renderBox?.size.height;
  }

  @override
  double get maxScrollExtent => _scrollController.position.maxScrollExtent;

  @override
  double get minScrollExtent => _scrollController.position.minScrollExtent;

  @override
  int? get page {
    if (onePageHeight != null) {
      final scrollExtent = maxScrollExtent - minScrollExtent;
      return (scrollExtent / onePageHeight!).ceil();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: CustomScrollView(
        key: _scrollViewKey,
        physics: const NeverScrollableScrollPhysics(),
        controller: _scrollController,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: widget.child,
          )
        ],
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
    Log.scroll.debug('disable scroll service');
  }

  @override
  void enable() {
    _scrollEnabled = true;
    Log.scroll.debug('enable scroll service');
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _scrollEnabled) {
      final dy = (_scrollController.position.pixels + event.scrollDelta.dy);
      scrollTo(dy);
    }
  }
}
