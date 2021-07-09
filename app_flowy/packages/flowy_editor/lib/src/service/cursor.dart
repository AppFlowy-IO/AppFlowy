import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../rendering/box.dart';

const Duration _FADE_DURATION = Duration(milliseconds: 250);

class CursorStyle {
  const CursorStyle({
    required this.color,
    required this.backgroundColor,
    this.width = 1.0,
    this.height,
    this.radius,
    this.offset,
    this.opacityAnimates = false,
    this.paintAboveText = false,
  });

  final Color color;
  final Color backgroundColor;
  final double width;
  final double? height;
  final Radius? radius;
  final Offset? offset;
  final bool opacityAnimates;
  final bool paintAboveText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          width == other.width &&
          height == other.height &&
          radius == other.radius &&
          offset == other.offset &&
          opacityAnimates == other.opacityAnimates &&
          paintAboveText == other.paintAboveText;

  @override
  int get hashCode =>
      color.hashCode ^
      backgroundColor.hashCode ^
      width.hashCode ^
      height.hashCode ^
      radius.hashCode ^
      offset.hashCode ^
      opacityAnimates.hashCode ^
      paintAboveText.hashCode;
}

/* ------------------------------- Controller ------------------------------- */

class CursorController extends ChangeNotifier {
  CursorController({
    required this.show,
    required CursorStyle style,
    required TickerProvider tickerProvider,
  })  : _style = style,
        _blink = ValueNotifier(false),
        color = ValueNotifier(style.color) {
    _blinkOpacityController =
        AnimationController(vsync: tickerProvider, duration: _FADE_DURATION);
    _blinkOpacityController.addListener(_onColorTick);
  }

  final ValueNotifier<bool> show;
  final ValueNotifier<bool> _blink;
  final ValueNotifier<Color> color;
  late AnimationController _blinkOpacityController;
  Timer? _cursorTimer;
  bool _targetCursorVisibility = false;
  CursorStyle _style;

  ValueNotifier<bool> get cursorBlink => _blink;

  ValueNotifier<Color> get cursorColor => color;

  CursorStyle get style => _style;

  set style(CursorStyle value) {
    if (_style == value) return;
    _style = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _blinkOpacityController.removeListener(_onColorTick);
    stopCursorTimer();
    _blinkOpacityController.dispose();
    assert(_cursorTimer == null);
    super.dispose();
  }

  void _cursorTick(Timer timer) {
    _targetCursorVisibility = !_targetCursorVisibility;
    final targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (style.opacityAnimates) {
      _blinkOpacityController.animateTo(targetOpacity, curve: Curves.easeOut);
    } else {
      _blinkOpacityController.value = targetOpacity;
    }
  }

  void _cursorWaitForStart(Timer timer) {
    _cursorTimer?.cancel();
    _cursorTimer =
        Timer.periodic(const Duration(milliseconds: 500), _cursorTick);
  }

  void startCursorTimer() {
    _targetCursorVisibility = true;
    _blinkOpacityController.value = 1.0;

    if (style.opacityAnimates) {
      _cursorTimer = Timer.periodic(
          const Duration(milliseconds: 150), _cursorWaitForStart);
    } else {
      _cursorTimer =
          Timer.periodic(const Duration(milliseconds: 500), _cursorTick);
    }
  }

  void stopCursorTimer({bool resetCharTicks = true}) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _blinkOpacityController.value = 0.0;

    if (style.opacityAnimates) {
      _blinkOpacityController
        ..stop()
        ..value = 0.0;
    }
  }

  void startOrStopCursorTimerIfNeeded(
      bool hasFocus, TextSelection textSelection) {
    if (show.value &&
        _cursorTimer == null &&
        hasFocus &&
        textSelection.isCollapsed) {
      startCursorTimer();
    } else if (_cursorTimer != null &&
        (!hasFocus || !textSelection.isCollapsed)) {
      stopCursorTimer();
    }
  }

  void _onColorTick() {
    color.value = _style.color.withOpacity(_blinkOpacityController.value);
    _blink.value = show.value && _blinkOpacityController.value > 0.0;
  }
}

/* --------------------------------- Painter -------------------------------- */

class CursorPainter {
  CursorPainter(
    this.editable,
    this.style,
    this.prototype,
    this.color,
    this.devicePixelRatio,
  );

  final RenderContentProxyBox? editable;
  final CursorStyle style;
  final Rect? prototype;
  final Color color;
  final double devicePixelRatio;

  void paint(Canvas canvas, Offset offset, TextPosition position) {
    assert(prototype != null);

    final caretOffset =
        editable!.getOffsetForCaret(position, prototype) + offset;
    var caretRect = prototype!.shift(caretOffset);
    if (style.offset != null) {
      caretRect = caretRect.shift(style.offset!);
    }

    if (caretRect.left < 0.0) {
      caretRect = caretRect.shift(Offset(-caretRect.left, 0));
    }

    final caretHeight = editable!.getFullHeightForCaret(position);
    if (caretHeight != null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top - 2.0,
            caretRect.width,
            caretHeight,
          );
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top + (caretHeight - caretRect.height) / 2,
            caretRect.width,
            caretRect.height,
          );
          break;
        default:
          throw UnimplementedError();
      }
    }

    final caretPosition = editable!.localToGlobal(caretRect.topLeft);
    final pixelMultiple = 1.0 / devicePixelRatio;
    caretRect = caretRect.shift(Offset(
        caretPosition.dx.isFinite
            ? (caretPosition.dx / pixelMultiple).round() * pixelMultiple -
                caretPosition.dx
            : caretPosition.dx,
        caretPosition.dy.isFinite
            ? (caretPosition.dy / pixelMultiple).round() * pixelMultiple -
                caretPosition.dy
            : caretPosition.dy));

    final paint = Paint()..color = color;
    if (style.radius == null) {
      canvas.drawRect(caretRect, paint);
      return;
    }

    final caretRRect = RRect.fromRectAndRadius(caretRect, style.radius!);
    canvas.drawRRect(caretRRect, paint);
  }
}
