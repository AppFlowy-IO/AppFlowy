import 'package:appflowy_backend/log.dart';
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
    this.enableCaching = true,
    this.debounceMs = 16, // One frame at 60fps
  });

  final String messageId;
  final Widget child;
  final HeightMeasuredCallback? onHeightMeasured;
  final bool enableCaching;
  final int debounceMs;

  @override
  State<MessageHeightCalculator> createState() =>
      _MessageHeightCalculatorState();
}

class _MessageHeightCalculatorState extends State<MessageHeightCalculator>
    with WidgetsBindingObserver {
  final GlobalKey _measureKey = GlobalKey();

  double? _lastMeasuredHeight;
  bool _isMeasuring = false;
  int _measurementAttempts = 0;
  static const int _maxMeasurementAttempts = 3;

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
    return Container(
      key: _measureKey,
      child: widget.child,
    );
  }

  void _resetMeasurement() {
    _lastMeasuredHeight = null;
    _isMeasuring = false;
    _measurementAttempts = 0;
  }

  void _scheduleMeasurement() {
    if (_isMeasuring || !mounted) return;

    _isMeasuring = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeight();
    });
  }

  void _measureHeight() {
    if (!mounted || _measurementAttempts >= _maxMeasurementAttempts) {
      _isMeasuring = false;
      return;
    }

    _measurementAttempts++;

    try {
      final renderBox =
          _measureKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null || !renderBox.hasSize) {
        // Retry measurement in next frame if render box is not ready
        if (_measurementAttempts < _maxMeasurementAttempts) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _measureHeight();
          });
        } else {
          _isMeasuring = false;
        }
        return;
      }

      final height = renderBox.size.height;

      if (_lastMeasuredHeight == null ||
          (height - (_lastMeasuredHeight ?? 0)).abs() > 1.0) {
        _lastMeasuredHeight = height;

        widget.onHeightMeasured?.call(widget.messageId, height);
      }

      _isMeasuring = false;
    } catch (e) {
      Log.error('[MessageHeightCalculator] Error measuring height', e);
      _isMeasuring = false;
    }
  }
}
