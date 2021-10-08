import 'dart:async';

import 'package:flutter/material.dart';

/// Scrollable list with arrow indicators.
///
/// The arrow indicators are automatically hidden if the list is not
/// scrollable in the direction of the respective arrow.
class ArrowIndicatedButtonList extends StatefulWidget {
  const ArrowIndicatedButtonList({required this.buttons, Key? key})
      : super(key: key);

  final List<Widget> buttons;

  @override
  _ArrowIndicatedButtonListState createState() =>
      _ArrowIndicatedButtonListState();
}

class _ArrowIndicatedButtonListState extends State<ArrowIndicatedButtonList>
    with WidgetsBindingObserver {
  final ScrollController _controller = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);

    // Listening to the WidgetsBinding instance is necessary so that we can
    // hide the arrows when the window gets a new size and thus the toolbar
    // becomes scrollable/unscrollable.
    WidgetsBinding.instance!.addObserver(this);

    // Workaround to allow the scroll controller attach to our ListView so that
    // we can detect if overflow arrows need to be shown on init.
    Timer.run(_handleScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildLeftArrow(),
        _buildScrollableList(),
        _buildRightColor(),
      ],
    );
  }

  @override
  void didChangeMetrics() => _handleScroll();

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;

    setState(() {
      _showLeftArrow =
          _controller.position.minScrollExtent != _controller.position.pixels;
      _showRightArrow =
          _controller.position.maxScrollExtent != _controller.position.pixels;
    });
  }

  Widget _buildLeftArrow() {
    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: _showLeftArrow ? const Icon(Icons.arrow_left, size: 18) : null,
      ),
    );
  }

  Widget _buildScrollableList() {
    return Expanded(
      child: ScrollConfiguration(
        // Remove the glowing effect, as we already have the arrow indicators
        behavior: _NoGlowBehavior(),
        // The CustomScrollView is necessary so that the children are not
        // stretched to the height of the toolbar, https://bit.ly/3uC3bjI
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.buttons,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRightColor() {
    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: _showRightArrow ? const Icon(Icons.arrow_right, size: 18) : null,
      ),
    );
  }
}

/// ScrollBehavior without the Material glow effect.
class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext _, Widget child, AxisDirection __) {
    return child;
  }
}
