import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../transitions.dart';

abstract class DragTargetData {
  int get draggingIndex;
}

abstract class ReorderFlexDraggableTargetBuilder {
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
    DragTargetWillAccepted<T> onWillAccept,
    AnimationController insertAnimationController,
    AnimationController deleteAnimationController,
  );
}

///
typedef DragTargetWillAccepted<T extends DragTargetData> = bool Function(
    T dragTargetData);

///
typedef DragTargetOnStarted = void Function(Widget, int, Size?);

typedef DragTargetOnMove<T extends DragTargetData> = void Function(
  T dragTargetData,
  Offset offset,
);

///
typedef DragTargetOnEnded<T extends DragTargetData> = void Function(
    T dragTargetData);

/// [ReorderDragTarget] is a [DragTarget] that carries the index information of
/// the child. You could check out this link for more information.
///
/// The size of the [ReorderDragTarget] will become zero when it start dragging.
///
class ReorderDragTarget<T extends DragTargetData> extends StatefulWidget {
  final Widget child;
  final T dragTargetData;

  final GlobalObjectKey indexGlobalKey;

  /// Called when dragTarget is being dragging.
  final DragTargetOnStarted onDragStarted;

  final DragTargetOnEnded<T> onDragEnded;

  final DragTargetOnMove<T> onDragMoved;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// [toAccept] represents the dragTarget index, which is the value passed in
  /// when creating the [ReorderDragTarget].
  final DragTargetWillAccepted<T> onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final void Function(T dragTargetData)? onAccept;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final void Function(T dragTargetData)? onLeave;

  final ReorderFlexDraggableTargetBuilder? draggableTargetBuilder;

  final AnimationController insertAnimationController;
  final AnimationController deleteAnimationController;

  final bool useMoveAnimation;
  final bool draggable;

  const ReorderDragTarget({
    Key? key,
    required this.child,
    required this.indexGlobalKey,
    required this.dragTargetData,
    required this.onDragStarted,
    required this.onDragMoved,
    required this.onDragEnded,
    required this.onWillAccept,
    required this.insertAnimationController,
    required this.deleteAnimationController,
    required this.useMoveAnimation,
    required this.draggable,
    this.onAccept,
    this.onLeave,
    this.draggableTargetBuilder,
  }) : super(key: key);

  @override
  State<ReorderDragTarget<T>> createState() => _ReorderDragTargetState<T>();
}

class _ReorderDragTargetState<T extends DragTargetData>
    extends State<ReorderDragTarget<T>> {
  /// Returns the dragTarget's size
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    Widget dragTarget = DragTarget<T>(
      builder: _buildDraggableWidget,
      onWillAccept: (dragTargetData) {
        assert(dragTargetData != null);
        if (dragTargetData == null) return false;
        return widget.onWillAccept(dragTargetData);
      },
      onAccept: widget.onAccept,
      onMove: (detail) {
        widget.onDragMoved(detail.data, detail.offset);
      },
      onLeave: (dragTargetData) {
        assert(dragTargetData != null);
        if (dragTargetData != null) {
          widget.onLeave?.call(dragTargetData);
        }
      },
    );

    dragTarget = KeyedSubtree(key: widget.indexGlobalKey, child: dragTarget);
    return dragTarget;
  }

  Widget _buildDraggableWidget(
    BuildContext context,
    List<T?> acceptedCandidates,
    List<dynamic> rejectedCandidates,
  ) {
    if (!widget.draggable) {
      return widget.child;
    }
    Widget feedbackBuilder = Builder(builder: (BuildContext context) {
      BoxConstraints contentSizeConstraints =
          BoxConstraints.loose(_draggingFeedbackSize!);
      return _buildDraggableFeedback(
        context,
        contentSizeConstraints,
        widget.child,
      );
    });

    final draggableWidget = widget.draggableTargetBuilder?.build(
          context,
          widget.child,
          widget.onDragStarted,
          widget.onDragEnded,
          widget.onWillAccept,
          widget.insertAnimationController,
          widget.deleteAnimationController,
        ) ??
        Draggable<DragTargetData>(
          maxSimultaneousDrags: 1,
          data: widget.dragTargetData,
          ignoringFeedbackSemantics: false,
          feedback: feedbackBuilder,
          childWhenDragging: IgnorePointerWidget(
            useIntrinsicSize: !widget.useMoveAnimation,
            child: widget.child,
          ),
          onDragStarted: () {
            _draggingFeedbackSize = widget.indexGlobalKey.currentContext?.size;
            widget.onDragStarted(
              widget.child,
              widget.dragTargetData.draggingIndex,
              _draggingFeedbackSize,
            );
          },
          dragAnchorStrategy: childDragAnchorStrategy,

          /// When the drag ends inside a DragTarget widget, the drag
          /// succeeds, and we reorder the widget into position appropriately.
          onDragCompleted: () {
            widget.onDragEnded(widget.dragTargetData);
          },

          /// When the drag does not end inside a DragTarget widget, the
          /// drag fails, but we still reorder the widget to the last position it
          /// had been dragged to.
          onDraggableCanceled: (Velocity velocity, Offset offset) =>
              widget.onDragEnded(widget.dragTargetData),
          child: widget.child,
        );

    return draggableWidget;
  }

  Widget _buildDraggableFeedback(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return Transform(
      transform: Matrix4.rotationZ(0),
      alignment: FractionalOffset.topLeft,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        clipBehavior: Clip.hardEdge,
        child: ConstrainedBox(
          constraints: constraints,
          child: Opacity(opacity: 0.3, child: child),
        ),
      ),
    );
  }
}

class DragTargetAnimation {
  // How long an animation to reorder an element in the list takes.
  final Duration reorderAnimationDuration;

  // This controls the entrance of the dragging widget into a new place.
  late AnimationController entranceController;

  // This controls the 'phantom' of the dragging widget, which is left behind
  // where the widget used to be.
  late AnimationController phantomController;

  late AnimationController insertController;

  late AnimationController deleteController;

  DragTargetAnimation({
    required this.reorderAnimationDuration,
    required TickerProvider vsync,
    required void Function(AnimationStatus) entranceAnimateStatusChanged,
  }) {
    entranceController = AnimationController(
        value: 1.0, vsync: vsync, duration: reorderAnimationDuration);
    entranceController.addStatusListener(entranceAnimateStatusChanged);

    phantomController = AnimationController(
        value: 0, vsync: vsync, duration: reorderAnimationDuration);

    insertController = AnimationController(
        value: 0.0, vsync: vsync, duration: const Duration(milliseconds: 200));

    deleteController = AnimationController(
        value: 0.0, vsync: vsync, duration: const Duration(milliseconds: 1));
  }

  void startDragging() {
    entranceController.value = 1.0;
  }

  void animateToNext() {
    phantomController.reverse(from: 1.0);
    entranceController.forward(from: 0.0);
  }

  void reverseAnimation() {
    phantomController.reverse(from: 0.1);
    entranceController.reverse(from: 0.0);
  }

  void dispose() {
    entranceController.dispose();
    phantomController.dispose();
    insertController.dispose();
    deleteController.dispose();
  }
}

class IgnorePointerWidget extends StatelessWidget {
  final Widget? child;
  final bool useIntrinsicSize;
  const IgnorePointerWidget({
    required this.child,
    this.useIntrinsicSize = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizedChild = useIntrinsicSize
        ? child
        : SizedBox(width: 0.0, height: 0.0, child: child);

    final opacity = useIntrinsicSize ? 0.3 : 0.0;
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: opacity,
        child: sizedChild,
      ),
    );
  }
}

class AbsorbPointerWidget extends StatelessWidget {
  final Widget? child;
  final bool useIntrinsicSize;
  const AbsorbPointerWidget({
    required this.child,
    this.useIntrinsicSize = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizedChild = useIntrinsicSize
        ? child
        : SizedBox(width: 0.0, height: 0.0, child: child);

    final opacity = useIntrinsicSize ? 0.3 : 0.0;
    return AbsorbPointer(
      child: Opacity(
        opacity: opacity,
        child: sizedChild,
      ),
    );
  }
}

class PhantomWidget extends StatelessWidget {
  final Widget? child;
  final double opacity;
  const PhantomWidget({
    this.child,
    this.opacity = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: child,
    );
  }
}

abstract class DragTargetMovePlaceholderDelegate {
  void registerPlaceholder(
    int dragTargetIndex,
    void Function(int currentDragTargetIndex) callback,
  );

  void unregisterPlaceholder(int dragTargetIndex);
}

class DragTargeMovePlaceholder extends StatefulWidget {
  final double height;
  final Color color;
  final Color highlightColor;
  final int dragTargetIndex;
  final DragTargetMovePlaceholderDelegate delegate;

  const DragTargeMovePlaceholder({
    required this.delegate,
    required this.dragTargetIndex,
    this.height = 4,
    this.color = Colors.transparent,
    this.highlightColor = Colors.lightBlue,
    Key? key,
  }) : super(key: key);

  @override
  State<DragTargeMovePlaceholder> createState() =>
      _DragTargeMovePlaceholderState();
}

class _DragTargeMovePlaceholderState extends State<DragTargeMovePlaceholder> {
  ValueNotifier<bool> isHighlight = ValueNotifier(false);

  @override
  void initState() {
    widget.delegate.registerPlaceholder(
      widget.dragTargetIndex,
      (currentDragTargetIndex) {
        if (!mounted) return;

        SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
          if (currentDragTargetIndex == -1) {
            isHighlight.value = false;
          } else {
            isHighlight.value =
                widget.dragTargetIndex == currentDragTargetIndex;
          }
        });
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    isHighlight.dispose();
    widget.delegate.unregisterPlaceholder(widget.dragTargetIndex);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: isHighlight,
      child: Consumer<ValueNotifier<bool>>(
        builder: (context, notifier, child) {
          return Container(
            height: widget.height,
            color: notifier.value ? widget.highlightColor : widget.color,
          );
        },
      ),
    );
  }
}

abstract class FakeDragTargetEventTrigger {
  void fakeOnDragStart(void Function(int?) callback);
  void fakeOnDragEnded(VoidCallback callback);
}

abstract class FakeDragTargetEventData {
  Size? get feedbackSize;
  int get index;
  DragTargetData get dragTargetData;
}

class FakeDragTarget<T extends DragTargetData> extends StatefulWidget {
  final Duration animationDuration;
  final FakeDragTargetEventTrigger eventTrigger;
  final FakeDragTargetEventData eventData;
  final DragTargetOnStarted onDragStarted;
  final DragTargetOnEnded<T> onDragEnded;
  final DragTargetWillAccepted<T> onWillAccept;
  final Widget child;
  final AnimationController insertAnimationController;
  final AnimationController deleteAnimationController;
  const FakeDragTarget({
    Key? key,
    required this.eventTrigger,
    required this.eventData,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onWillAccept,
    required this.insertAnimationController,
    required this.deleteAnimationController,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 250),
  }) : super(key: key);

  @override
  State<FakeDragTarget<T>> createState() => _FakeDragTargetState<T>();
}

class _FakeDragTargetState<T extends DragTargetData>
    extends State<FakeDragTarget<T>>
    with TickerProviderStateMixin<FakeDragTarget<T>> {
  bool simulateDragging = false;

  @override
  void initState() {
    widget.insertAnimationController.addStatusListener(
      _onInsertedAnimationStatusChanged,
    );

    /// Start insert animation
    widget.insertAnimationController.forward(from: 0.0);

    // widget.eventTrigger.fakeOnDragStart((insertIndex) {
    //   Log.trace("[$FakeDragTarget] on drag $insertIndex");
    // });

    widget.eventTrigger.fakeOnDragEnded(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDragEnded(widget.eventData.dragTargetData as T);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (simulateDragging) {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: widget.deleteAnimationController,
        axis: Axis.vertical,
        child: AbsorbPointerWidget(
          child: widget.child,
        ),
      );
    } else {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: widget.insertAnimationController,
        axis: Axis.vertical,
        child: AbsorbPointerWidget(
          useIntrinsicSize: true,
          child: widget.child,
        ),
      );
    }
  }

  void _onInsertedAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        simulateDragging = true;
        widget.deleteAnimationController.reverse(from: 1.0);
        widget.onWillAccept(widget.eventData.dragTargetData as T);
        widget.onDragStarted(
          widget.child,
          widget.eventData.index,
          widget.eventData.feedbackSize,
        );
      });
    });
  }
}
