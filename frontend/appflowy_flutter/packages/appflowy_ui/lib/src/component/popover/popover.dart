import 'dart:ui';

import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:appflowy_ui/src/component/popover/shadcn/_mouse_area.dart';
import 'package:appflowy_ui/src/component/popover/shadcn/_portal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

export 'anchor.dart';

/// Notes: The implementation of this page is copied from [flutter_shadcn_ui](https://github.com/nank1ro/flutter-shadcn-ui).
///
/// Renaming is for the consistency of the AppFlowy UI.

/// Controls the visibility of a [AFPopover].
class AFPopoverController extends ChangeNotifier {
  AFPopoverController({bool isOpen = false}) : _isOpen = isOpen;

  bool _isOpen = false;

  /// Indicates if the popover is visible.
  bool get isOpen => _isOpen;

  /// Displays the popover.
  void show() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  /// Hides the popover.
  void hide() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void setOpen(bool open) {
    if (_isOpen == open) return;
    _isOpen = open;
    notifyListeners();
  }

  /// Toggles the visibility of the popover.
  void toggle() => _isOpen ? hide() : show();
}

class AFPopover extends StatefulWidget {
  const AFPopover({
    super.key,
    required this.child,
    required this.popover,
    this.controller,
    this.visible,
    this.closeOnTapOutside = true,
    this.focusNode,
    this.anchor,
    this.effects,
    this.shadows,
    this.padding,
    this.decoration,
    this.filter,
    this.groupId,
    this.areaGroupId,
    this.useSameGroupIdForChild = true,
  }) : assert(
          (controller != null) ^ (visible != null),
          'Either controller or visible must be provided',
        );

  /// {@template ShadPopover.popover}
  /// The widget displayed as a popover.
  /// {@endtemplate}
  final WidgetBuilder popover;

  /// {@template ShadPopover.child}
  /// The child widget.
  /// {@endtemplate}
  final Widget child;

  /// {@template ShadPopover.controller}
  /// The controller that controls the visibility of the [popover].
  /// {@endtemplate}
  final AFPopoverController? controller;

  /// {@template ShadPopover.visible}
  /// Indicates if the popover should be visible.
  /// {@endtemplate}
  final bool? visible;

  /// {@template ShadPopover.closeOnTapOutside}
  /// Closes the popover when the user taps outside, defaults to true.
  /// {@endtemplate}
  final bool closeOnTapOutside;

  /// {@template ShadPopover.focusNode}
  /// The focus node of the child, the [popover] will be shown when
  /// focused.
  /// {@endtemplate}
  final FocusNode? focusNode;

  ///{@template ShadPopover.anchor}
  /// The position of the [popover] in the global coordinate system.
  ///
  /// Defaults to `ShadAnchorAuto()`.
  /// {@endtemplate}
  final ShadAnchorBase? anchor;

  /// {@template ShadPopover.effects}
  /// The animation effects applied to the [popover]. Defaults to
  /// [FadeEffect(), ScaleEffect(begin: Offset(.95, .95), end: Offset(1, 1)),
  /// MoveEffect(begin: Offset(0, 2), end: Offset(0, 0))].
  /// {@endtemplate}
  final List<Effect<dynamic>>? effects;

  /// {@template ShadPopover.shadows}
  /// The shadows applied to the [popover], defaults to
  /// [ShadShadows.md].
  /// {@endtemplate}
  final List<BoxShadow>? shadows;

  /// {@template ShadPopover.padding}
  /// The padding of the [popover], defaults to
  /// `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`.
  /// {@endtemplate}
  final EdgeInsetsGeometry? padding;

  /// {@template ShadPopover.decoration}
  /// The decoration of the [popover].
  /// {@endtemplate}
  final BoxDecoration? decoration;

  /// {@template ShadPopover.filter}
  /// The filter of the [popover], defaults to `null`.
  /// {@endtemplate}
  final ImageFilter? filter;

  /// {@template ShadPopover.groupId}
  /// The group id of the [popover], defaults to `UniqueKey()`.
  ///
  /// Used to determine it the tap is inside the [popover] or not.
  /// {@endtemplate}
  final Object? groupId;

  /// {@macro ShadMouseArea.groupId}
  final Object? areaGroupId;

  /// {@template ShadPopover.useSameGroupIdForChild}
  /// Whether the [groupId] should be used for the child widget, defaults to
  /// `true`. This teams that taps on the child widget will be handled as inside
  /// the popover.
  /// {@endtemplate}
  final bool useSameGroupIdForChild;

  @override
  State<AFPopover> createState() => _AFPopoverState();
}

class _AFPopoverState extends State<AFPopover> {
  static final List<_AFPopoverState> _openPopovers = [];
  static int? _lastPopoverClosedTimestamp;
  static void _markPopoverClosedThisFrame() {
    _lastPopoverClosedTimestamp = DateTime.now().microsecondsSinceEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastPopoverClosedTimestamp = null;
    });
  }

  AFPopoverController? _controller;
  AFPopoverController get controller => widget.controller ?? _controller!;
  bool animating = false;

  late final _popoverKey = UniqueKey();

  Object get groupId => widget.groupId ?? _popoverKey;

  bool get _isTopMostPopover =>
      _openPopovers.isNotEmpty && _openPopovers.last == this;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = AFPopoverController();
    }
    controller.addListener(_onControllerChanged);
    if (controller.isOpen) {
      _registerPopover();
    }
  }

  void _onControllerChanged() {
    if (controller.isOpen) {
      _registerPopover();
    } else {
      _unregisterPopover();
    }
  }

  @override
  void didUpdateWidget(covariant AFPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != null) {
      if (widget.visible! && !controller.isOpen) {
        controller.show();
      } else if (!widget.visible! && controller.isOpen) {
        controller.hide();
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _unregisterPopover();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    final effectiveEffects = widget.effects ?? [];
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.l,
        );

    final effectiveAnchor = widget.anchor ?? const ShadAnchorAuto();
    final effectiveDecoration = widget.decoration ??
        BoxDecoration(
          color: theme.surfaceColorScheme.layer01,
          borderRadius: BorderRadius.circular(theme.borderRadius.m),
          boxShadow: theme.shadow.medium,
        );

    final effectiveFilter = widget.filter;

    Widget popover = ShadMouseArea(
      groupId: widget.areaGroupId,
      child: DecoratedBox(
        decoration: effectiveDecoration,
        child: Padding(
          padding: effectivePadding,
          child: DefaultTextStyle(
            style: TextStyle(
              color: theme.textColorScheme.primary,
            ),
            child: Builder(
              builder: widget.popover,
            ),
          ),
        ),
      ),
    );

    if (effectiveFilter != null) {
      popover = BackdropFilter(
        filter: widget.filter!,
        child: popover,
      );
    }

    if (effectiveEffects.isNotEmpty) {
      popover = Animate(
        effects: effectiveEffects,
        child: popover,
      );
    }

    if (widget.closeOnTapOutside) {
      popover = TapRegion(
        groupId: groupId,
        behavior: HitTestBehavior.opaque,
        onTapOutside: (_) {
          final now = DateTime.now().microsecondsSinceEpoch;
          if (_isTopMostPopover &&
              (_lastPopoverClosedTimestamp == null ||
                  now - _lastPopoverClosedTimestamp! > 1000)) {
            controller.hide();
            _markPopoverClosedThisFrame();
          }
        },
        child: popover,
      );
    }

    Widget child = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              controller.hide();
            },
          },
          child: ShadPortal(
            portalBuilder: (_) => popover,
            visible: controller.isOpen,
            anchor: effectiveAnchor,
            child: widget.child,
          ),
        );
      },
    );

    if (widget.useSameGroupIdForChild) {
      child = TapRegion(
        groupId: groupId,
        child: child,
      );
    }
    return child;
  }

  void _registerPopover() {
    if (!_openPopovers.contains(this)) {
      _openPopovers.add(this);
    }
  }

  void _unregisterPopover() {
    _openPopovers.remove(this);
  }
}
