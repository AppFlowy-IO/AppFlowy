import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Callback type for height measurement
typedef HeightMeasuredCallback = void Function(String messageId, double height);

/// Widget that measures and caches message heights with proper lifecycle management
class MessageHeightCalculator extends StatefulWidget {
  const MessageHeightCalculator({
    super.key,
    required this.messageId,
    required this.child,
    this.onHeightMeasured,
  });

  final String messageId;
  final Widget child;
  final HeightMeasuredCallback? onHeightMeasured;

  @override
  State<MessageHeightCalculator> createState() =>
      _MessageHeightCalculatorState();
}

class _MessageHeightCalculatorState extends State<MessageHeightCalculator>
    with WidgetsBindingObserver {
  final GlobalKey measureKey = GlobalKey();

  double? lastMeasuredHeight;
  bool isMeasuring = false;
  int measurementAttempts = 0;
  static const int maxMeasurementAttempts = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(MessageHeightCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.messageId != widget.messageId) {
      _resetMeasurement();
      _scheduleMeasurement();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      _scheduleMeasurement();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: measureKey,
      child: widget.child,
    );
  }

  void _resetMeasurement() {
    lastMeasuredHeight = null;
    isMeasuring = false;
    measurementAttempts = 0;
  }

  void _scheduleMeasurement() {
    if (isMeasuring || !mounted) return;

    isMeasuring = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeight();
    });
  }

  void _measureHeight() {
    if (!mounted || measurementAttempts >= maxMeasurementAttempts) {
      isMeasuring = false;
      return;
    }

    measurementAttempts++;

    try {
      final renderBox =
          measureKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null || !renderBox.hasSize) {
        // Retry measurement in next frame if render box is not ready
        if (measurementAttempts < maxMeasurementAttempts) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _measureHeight();
          });
        } else {
          isMeasuring = false;
        }
        return;
      }

      final height = renderBox.size.height;

      if (lastMeasuredHeight == null ||
          (height - (lastMeasuredHeight ?? 0)).abs() > 1.0) {
        lastMeasuredHeight = height;

        widget.onHeightMeasured?.call(widget.messageId, height);
      }

      isMeasuring = false;
    } catch (e) {
      isMeasuring = false;
    }
  }
}
