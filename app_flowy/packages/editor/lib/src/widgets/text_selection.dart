import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../models/documents/nodes/node.dart';
import 'editor.dart';

TextSelection localSelection(Node node, TextSelection selection, fromParent) {
  final base = fromParent ? node.offset : node.documentOffset;
  assert(base <= selection.end && selection.start <= base + node.length - 1);

  final offset = fromParent ? node.offset : node.documentOffset;
  return selection.copyWith(
      baseOffset: math.max(selection.start - offset, 0),
      extentOffset: math.min(selection.end - offset, node.length - 1));
}

enum _TextSelectionHandlePosition { START, END }

/// internal use, used to get drag direction information
class DragTextSelection extends TextSelection {
  const DragTextSelection({
    TextAffinity affinity = TextAffinity.downstream,
    int baseOffset = 0,
    int extentOffset = 0,
    bool isDirectional = false,
    this.first = true,
  }) : super(
          baseOffset: baseOffset,
          extentOffset: extentOffset,
          affinity: affinity,
          isDirectional: isDirectional,
        );

  final bool first;

  @override
  DragTextSelection copyWith({
    int? baseOffset,
    int? extentOffset,
    TextAffinity? affinity,
    bool? isDirectional,
    bool? first,
  }) {
    return DragTextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      affinity: affinity ?? this.affinity,
      isDirectional: isDirectional ?? this.isDirectional,
      first: first ?? this.first,
    );
  }
}

class EditorTextSelectionOverlay {
  EditorTextSelectionOverlay(
    this.value,
    this.handlesVisible,
    this.context,
    this.debugRequiredFor,
    this.toolbarLayerLink,
    this.startHandleLayerLink,
    this.endHandleLayerLink,
    this.renderObject,
    this.selectionCtrls,
    this.selectionDelegate,
    this.dragStartBehavior,
    this.onSelectionHandleTapped,
    this.clipboardStatus,
  ) {
    final overlay = Overlay.of(context, rootOverlay: true)!;

    _toolbarController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: overlay);
  }

  TextEditingValue value;
  bool handlesVisible = false;
  final BuildContext context;
  final Widget debugRequiredFor;
  final LayerLink toolbarLayerLink;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final RenderEditor? renderObject;
  final TextSelectionControls selectionCtrls;
  final TextSelectionDelegate selectionDelegate;
  final DragStartBehavior dragStartBehavior;
  final VoidCallback? onSelectionHandleTapped;
  final ClipboardStatusNotifier clipboardStatus;
  late AnimationController _toolbarController;
  List<OverlayEntry>? _handles;
  OverlayEntry? toolbar;

  TextSelection get _selection => value.selection;

  Animation<double> get _toolbarOpacity => _toolbarController.view;

  void setHandlesVisible(bool visible) {
    if (handlesVisible == visible) {
      return;
    }
    handlesVisible = visible;
    if (SchedulerBinding.instance!.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance!.addPostFrameCallback(markNeedsBuild);
    } else {
      markNeedsBuild();
    }
  }

  void hideHandles() {
    if (_handles == null) {
      return;
    }
    _handles![0].remove();
    _handles![1].remove();
    _handles = null;
  }

  void hideToolbar() {
    assert(toolbar != null);
    _toolbarController.stop();
    toolbar!.remove();
    toolbar = null;
  }

  void showToolbar() {
    assert(toolbar == null);
    toolbar = OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)!
        .insert(toolbar!);
    _toolbarController.forward(from: 0);
  }

  Widget _buildHandle(
      BuildContext context, _TextSelectionHandlePosition position) {
    if (_selection.isCollapsed &&
        position == _TextSelectionHandlePosition.END) {
      return Container();
    }
    return Visibility(
        visible: handlesVisible,
        child: _TextSelectionHandleOverlay(
          onSelectionHandleChanged: (newSelection) {
            _handleSelectionHandleChanged(newSelection, position);
          },
          onSelectionHandleTapped: onSelectionHandleTapped,
          startHandleLayerLink: startHandleLayerLink,
          endHandleLayerLink: endHandleLayerLink,
          renderObject: renderObject,
          selection: _selection,
          selectionControls: selectionCtrls,
          position: position,
          dragStartBehavior: dragStartBehavior,
        ));
  }

  void update(TextEditingValue newValue) {
    if (value == newValue) {
      return;
    }
    value = newValue;
    if (SchedulerBinding.instance!.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance!.addPostFrameCallback(markNeedsBuild);
    } else {
      markNeedsBuild();
    }
  }

  void _handleSelectionHandleChanged(
      TextSelection? newSelection, _TextSelectionHandlePosition position) {
    TextPosition textPosition;
    switch (position) {
      case _TextSelectionHandlePosition.START:
        textPosition = newSelection != null
            ? newSelection.base
            : const TextPosition(offset: 0);
        break;
      case _TextSelectionHandlePosition.END:
        textPosition = newSelection != null
            ? newSelection.extent
            : const TextPosition(offset: 0);
        break;
      default:
        throw 'Invalid position';
    }

    final currSelection = newSelection != null
        ? DragTextSelection(
            baseOffset: newSelection.baseOffset,
            extentOffset: newSelection.extentOffset,
            affinity: newSelection.affinity,
            isDirectional: newSelection.isDirectional,
            first: position == _TextSelectionHandlePosition.START,
          )
        : null;

    selectionDelegate
      ..userUpdateTextEditingValue(
          value.copyWith(selection: currSelection, composing: TextRange.empty),
          SelectionChangedCause.drag)
      ..bringIntoView(textPosition);
  }

  Widget _buildToolbar(BuildContext context) {
    final endpoints = renderObject!.getEndpointsForSelection(_selection);

    final editingRegion = Rect.fromPoints(
      renderObject!.localToGlobal(Offset.zero),
      renderObject!.localToGlobal(renderObject!.size.bottomRight(Offset.zero)),
    );

    final baseLineHeight = renderObject!.preferredLineHeight(_selection.base);
    final extentLineHeight =
        renderObject!.preferredLineHeight(_selection.extent);
    final smallestLineHeight = math.min(baseLineHeight, extentLineHeight);
    final isMultiline = endpoints.last.point.dy - endpoints.first.point.dy >
        smallestLineHeight / 2;

    final midX = isMultiline
        ? editingRegion.width / 2
        : (endpoints.first.point.dx + endpoints.last.point.dx) / 2;

    final midpoint = Offset(
      midX,
      endpoints[0].point.dy - baseLineHeight,
    );

    return FadeTransition(
      opacity: _toolbarOpacity,
      child: CompositedTransformFollower(
        link: toolbarLayerLink,
        showWhenUnlinked: false,
        offset: -editingRegion.topLeft,
        child: selectionCtrls.buildToolbar(
            context,
            editingRegion,
            baseLineHeight,
            midpoint,
            endpoints,
            selectionDelegate,
            clipboardStatus,
            const Offset(0, 0)),
      ),
    );
  }

  void markNeedsBuild([Duration? duration]) {
    if (_handles != null) {
      _handles![0].markNeedsBuild();
      _handles![1].markNeedsBuild();
    }
    toolbar?.markNeedsBuild();
  }

  void hide() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
    if (toolbar != null) {
      hideToolbar();
    }
  }

  void dispose() {
    hide();
    _toolbarController.dispose();
  }

  void showHandles() {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      OverlayEntry(
          builder: (context) =>
              _buildHandle(context, _TextSelectionHandlePosition.START)),
      OverlayEntry(
          builder: (context) =>
              _buildHandle(context, _TextSelectionHandlePosition.END)),
    ];

    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)!
        .insertAll(_handles!);
  }
}

class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    required this.selection,
    required this.position,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.renderObject,
    required this.onSelectionHandleChanged,
    required this.onSelectionHandleTapped,
    required this.selectionControls,
    this.dragStartBehavior = DragStartBehavior.start,
    Key? key,
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final RenderEditor? renderObject;
  final ValueChanged<TextSelection?> onSelectionHandleChanged;
  final VoidCallback? onSelectionHandleTapped;
  final TextSelectionControls selectionControls;
  final DragStartBehavior dragStartBehavior;

  @override
  _TextSelectionHandleOverlayState createState() =>
      _TextSelectionHandleOverlayState();

  ValueListenable<bool>? get _visibility {
    switch (position) {
      case _TextSelectionHandlePosition.START:
        return renderObject!.selectionStartInViewport;
      case _TextSelectionHandlePosition.END:
        return renderObject!.selectionEndInViewport;
    }
  }
}

class _TextSelectionHandleOverlayState
    extends State<_TextSelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  late Offset _dragPosition;
  late Size _handleSize;
  late AnimationController _controller;

  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);

    _handleVisibilityChanged();
    widget._visibility!.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget._visibility!.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_TextSelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget._visibility!.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget._visibility!.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget._visibility!.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragPosition = details.globalPosition + Offset(0, -_handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final position = widget.renderObject!.getPositionForOffset(_dragPosition);
    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(TextSelection.fromPosition(position));
      return;
    }

    final isNormalized =
        widget.selection.extentOffset >= widget.selection.baseOffset;
    TextSelection? newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.START:
        newSelection = TextSelection(
          baseOffset:
              isNormalized ? position.offset : widget.selection.baseOffset,
          extentOffset:
              isNormalized ? widget.selection.extentOffset : position.offset,
        );
        break;
      case _TextSelectionHandlePosition.END:
        newSelection = TextSelection(
          baseOffset:
              isNormalized ? widget.selection.baseOffset : position.offset,
          extentOffset:
              isNormalized ? position.offset : widget.selection.extentOffset,
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset) {
      return; // don't allow order swapping.
    }

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    if (widget.onSelectionHandleTapped != null) {
      widget.onSelectionHandleTapped!();
    }
  }

  @override
  Widget build(BuildContext context) {
    late LayerLink layerLink;
    TextSelectionHandleType? type;

    switch (widget.position) {
      case _TextSelectionHandlePosition.START:
        layerLink = widget.startHandleLayerLink;
        type = _chooseType(
          widget.renderObject!.textDirection,
          TextSelectionHandleType.left,
          TextSelectionHandleType.right,
        );
        break;
      case _TextSelectionHandlePosition.END:
        assert(!widget.selection.isCollapsed);
        layerLink = widget.endHandleLayerLink;
        type = _chooseType(
          widget.renderObject!.textDirection,
          TextSelectionHandleType.right,
          TextSelectionHandleType.left,
        );
        break;
    }

    final textPosition = widget.position == _TextSelectionHandlePosition.START
        ? widget.selection.base
        : widget.selection.extent;
    final lineHeight = widget.renderObject!.preferredLineHeight(textPosition);
    final handleAnchor =
        widget.selectionControls.getHandleAnchor(type!, lineHeight);
    final handleSize = widget.selectionControls.getHandleSize(lineHeight);
    _handleSize = handleSize;

    final handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    final interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveDimension / 2),
    );
    final padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: layerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: widget.dragStartBehavior,
            onPanStart: _handleDragStart,
            onPanUpdate: _handleDragUpdate,
            onTap: _handleTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                type,
                lineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSelectionHandleType? _chooseType(
    TextDirection textDirection,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    if (widget.selection.isCollapsed) return TextSelectionHandleType.collapsed;

    switch (textDirection) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
  }
}

class EditorTextSelectionGestureDetector extends StatefulWidget {
  const EditorTextSelectionGestureDetector({
    required this.child,
    this.onTapDown,
    this.onForcePressStart,
    this.onForcePressEnd,
    this.onSingleTapUp,
    this.onSingleTapCancel,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.onDoubleTapDown,
    this.onDragSelectionStart,
    this.onDragSelectionUpdate,
    this.onDragSelectionEnd,
    this.behavior,
    Key? key,
  }) : super(key: key);

  final GestureTapDownCallback? onTapDown;

  final GestureForcePressStartCallback? onForcePressStart;

  final GestureForcePressEndCallback? onForcePressEnd;

  final GestureTapUpCallback? onSingleTapUp;

  final GestureTapCancelCallback? onSingleTapCancel;

  final GestureLongPressStartCallback? onSingleLongTapStart;

  final GestureLongPressMoveUpdateCallback? onSingleLongTapMoveUpdate;

  final GestureLongPressEndCallback? onSingleLongTapEnd;

  final GestureTapDownCallback? onDoubleTapDown;

  final GestureDragStartCallback? onDragSelectionStart;

  final DragSelectionUpdateCallback? onDragSelectionUpdate;

  final GestureDragEndCallback? onDragSelectionEnd;

  final HitTestBehavior? behavior;

  final Widget child;

  @override
  State<StatefulWidget> createState() =>
      _EditorTextSelectionGestureDetectorState();
}

class _EditorTextSelectionGestureDetectorState
    extends State<EditorTextSelectionGestureDetector> {
  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;
  bool _isDoubleTap = false;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _dragUpdateThrottleTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    // renderObject.resetTapDownStatus();
    if (widget.onTapDown != null) {
      widget.onTapDown!(details);
    }
    if (_doubleTapTimer != null &&
        _isWithinDoubleTapTolerance(details.globalPosition)) {
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown!(details);
      }

      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      if (widget.onSingleTapUp != null) {
        widget.onSingleTapUp!(details);
      }
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }
    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    if (widget.onSingleTapCancel != null) {
      widget.onSingleTapCancel!();
    }
  }

  DragStartDetails? _lastDragStartDetails;
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;
    if (widget.onDragSelectionStart != null) {
      widget.onDragSelectionStart!(details);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _lastDragUpdateDetails = details;
    _dragUpdateThrottleTimer ??=
        Timer(const Duration(milliseconds: 50), _handleDragUpdateThrottled);
  }

  void _handleDragUpdateThrottled() {
    assert(_lastDragStartDetails != null);
    assert(_lastDragUpdateDetails != null);
    if (widget.onDragSelectionUpdate != null) {
      widget.onDragSelectionUpdate!(
          _lastDragStartDetails!, _lastDragUpdateDetails!);
    }
    _dragUpdateThrottleTimer = null;
    _lastDragUpdateDetails = null;
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_lastDragStartDetails != null);
    if (_dragUpdateThrottleTimer != null) {
      _dragUpdateThrottleTimer!.cancel();
      _handleDragUpdateThrottled();
    }
    if (widget.onDragSelectionEnd != null) {
      widget.onDragSelectionEnd!(details);
    }
    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    if (widget.onForcePressStart != null) {
      widget.onForcePressStart!(details);
    }
  }

  void _forcePressEnded(ForcePressDetails details) {
    if (widget.onForcePressEnd != null) {
      widget.onForcePressEnd!(details);
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapStart != null) {
      widget.onSingleLongTapStart!(details);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapMoveUpdate != null) {
      widget.onSingleLongTapMoveUpdate!(details);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapEnd != null) {
      widget.onSingleLongTapEnd!(details);
    }
    _isDoubleTap = false;
  }

  void _doubleTapTimeout() {
    _doubleTapTimer = null;
    _lastTapOffset = null;
  }

  bool _isWithinDoubleTapTolerance(Offset secondTapOffset) {
    if (_lastTapOffset == null) {
      return false;
    }

    return (secondTapOffset - _lastTapOffset!).distance <= kDoubleTapSlop;
  }

  @override
  Widget build(BuildContext context) {
    final gestures = <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (instance) {
        instance
          ..onTapDown = _handleTapDown
          ..onTapUp = _handleTapUp
          ..onTapCancel = _handleTapCancel;
      },
    );

    if (widget.onSingleLongTapStart != null ||
        widget.onSingleLongTapMoveUpdate != null ||
        widget.onSingleLongTapEnd != null) {
      gestures[LongPressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(
            debugOwner: this,
            supportedDevices: <PointerDeviceKind>{PointerDeviceKind.touch}),
        (instance) {
          instance
            ..onLongPressStart = _handleLongPressStart
            ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
            ..onLongPressEnd = _handleLongPressEnd;
        },
      );
    }

    if (widget.onDragSelectionStart != null ||
        widget.onDragSelectionUpdate != null ||
        widget.onDragSelectionEnd != null) {
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(
            debugOwner: this,
            supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
        (instance) {
          instance
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd;
        },
      );
    }

    if (widget.onForcePressStart != null || widget.onForcePressEnd != null) {
      gestures[ForcePressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        () => ForcePressGestureRecognizer(debugOwner: this),
        (instance) {
          instance
            ..onStart =
                widget.onForcePressStart != null ? _forcePressStarted : null
            ..onEnd = widget.onForcePressEnd != null ? _forcePressEnded : null;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      excludeFromSemantics: true,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}
