import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Notes: The implementation of this page is copied from [flutter_shadcn_ui](https://github.com/nank1ro/flutter-shadcn-ui).

abstract class MouseAreaRegistry {
  /// Register the given [ShadMouseAreaRenderBox] with the registry.
  void registerMouseArea(ShadMouseAreaRenderBox region);

  /// Unregister the given [ShadMouseAreaRenderBox] with the registry.
  void unregisterMouseArea(ShadMouseAreaRenderBox region);

  /// Allows finding of the nearest [MouseAreaRegistry], such as a
  /// [MouseAreaSurfaceRenderBox].
  static MouseAreaRegistry? maybeOf(BuildContext context) {
    return context.findAncestorRenderObjectOfType<MouseAreaSurfaceRenderBox>();
  }

  /// Allows finding of the nearest [MouseAreaRegistry], such as a
  /// [MouseAreaSurfaceRenderBox].
  ///
  /// Will throw if a [MouseAreaRegistry] isn't found.
  static MouseAreaRegistry of(BuildContext context) {
    final registry = maybeOf(context);
    assert(() {
      if (registry == null) {
        throw FlutterError(
          '''
MouseRegionRegistry.of() was called with a context that does not contain a MouseRegionSurface widget.\n
  No MouseRegionSurface widget ancestor could be found starting from the context that was passed to
  MouseRegionRegistry.of().\n
  The context used was:\n
    $context
''',
        );
      }
      return true;
    }());
    return registry!;
  }
}

class MouseAreaSurfaceRenderBox extends RenderProxyBoxWithHitTestBehavior
    implements MouseAreaRegistry {
  final Expando<BoxHitTestResult> _cachedResults = Expando<BoxHitTestResult>();
  final Set<ShadMouseAreaRenderBox> _registeredRegions =
      <ShadMouseAreaRenderBox>{};
  final Map<Object?, Set<ShadMouseAreaRenderBox>> _groupIdToRegions =
      <Object?, Set<ShadMouseAreaRenderBox>>{};

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    assert(
      () {
        for (final region in _registeredRegions) {
          if (!region.enabled) {
            return false;
          }
        }
        return true;
      }(),
      'A MouseAreaRegion was registered when it was disabled.',
    );

    if (_registeredRegions.isEmpty) {
      return;
    }

    final result = _cachedResults[entry];

    if (result == null) {
      return;
    }

    // A child was hit, so we need to call onExit for those regions or
    // groups of regions that were not hit.
    final hitRegions = _getRegionsHit(_registeredRegions, result.path)
        .cast<ShadMouseAreaRenderBox>()
        .toSet();

    final insideRegions = <ShadMouseAreaRenderBox>{
      for (final ShadMouseAreaRenderBox region in hitRegions)
        if (region.groupId == null)
          region
        // Adding all grouped regions, so they act as a single region.
        else
          ..._groupIdToRegions[region.groupId]!,
    };
    // If they're not inside, then they're outside.
    final outsideRegions = _registeredRegions.difference(insideRegions);
    for (final region in outsideRegions) {
      region.onExit?.call(
        PointerExitEvent(
          viewId: event.viewId,
          timeStamp: event.timeStamp,
          pointer: event.pointer,
          device: event.device,
          position: event.position,
          delta: event.delta,
          buttons: event.buttons,
          obscured: event.obscured,
          pressureMin: event.pressureMin,
          pressureMax: event.pressureMax,
          distance: event.distance,
          distanceMax: event.distanceMax,
          size: event.size,
          radiusMajor: event.radiusMajor,
          radiusMinor: event.radiusMinor,
          radiusMin: event.radiusMin,
          radiusMax: event.radiusMax,
          orientation: event.orientation,
          tilt: event.tilt,
          down: event.down,
          synthesized: event.synthesized,
          embedderId: event.embedderId,
        ),
      );
    }
    for (final region in insideRegions) {
      region.onEnter?.call(
        PointerEnterEvent(
          viewId: event.viewId,
          timeStamp: event.timeStamp,
          pointer: event.pointer,
          device: event.device,
          position: event.position,
          delta: event.delta,
          buttons: event.buttons,
          obscured: event.obscured,
          pressureMin: event.pressureMin,
          pressureMax: event.pressureMax,
          distance: event.distance,
          distanceMax: event.distanceMax,
          size: event.size,
          radiusMajor: event.radiusMajor,
          radiusMinor: event.radiusMinor,
          radiusMin: event.radiusMin,
          radiusMax: event.radiusMax,
          orientation: event.orientation,
          tilt: event.tilt,
          down: event.down,
          synthesized: event.synthesized,
          embedderId: event.embedderId,
        ),
      );
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) {
      return false;
    }

    final hitTarget =
        hitTestChildren(result, position: position) || hitTestSelf(position);

    if (hitTarget) {
      final entry = BoxHitTestEntry(this, position);
      _cachedResults[entry] = result;
      result.add(entry);
    }

    return hitTarget;
  }

  @override
  void registerMouseArea(ShadMouseAreaRenderBox region) {
    assert(!_registeredRegions.contains(region));
    _registeredRegions.add(region);
    if (region.groupId != null) {
      _groupIdToRegions[region.groupId] ??= <ShadMouseAreaRenderBox>{};
      _groupIdToRegions[region.groupId]!.add(region);
    }
  }

  @override
  void unregisterMouseArea(ShadMouseAreaRenderBox region) {
    assert(_registeredRegions.contains(region));
    _registeredRegions.remove(region);
    if (region.groupId != null) {
      assert(_groupIdToRegions.containsKey(region.groupId));
      _groupIdToRegions[region.groupId]!.remove(region);
      if (_groupIdToRegions[region.groupId]!.isEmpty) {
        _groupIdToRegions.remove(region.groupId);
      }
    }
  }

  // Returns the registered regions that are in the hit path.
  Set<HitTestTarget> _getRegionsHit(
    Set<ShadMouseAreaRenderBox> detectors,
    Iterable<HitTestEntry> hitTestPath,
  ) {
    return <HitTestTarget>{
      for (final HitTestEntry<HitTestTarget> entry in hitTestPath)
        if (entry.target case final HitTestTarget target)
          if (_registeredRegions.contains(target)) target,
    };
  }
}

class ShadMouseArea extends SingleChildRenderObjectWidget {
  /// Creates a const [ShadMouseArea].
  ///
  /// The [child] argument is required.
  const ShadMouseArea({
    super.key,
    super.child,
    this.enabled = true,
    this.behavior = HitTestBehavior.deferToChild,
    this.groupId,
    this.onEnter,
    this.onExit,
    this.cursor = MouseCursor.defer,
    String? debugLabel,
  }) : debugLabel = kReleaseMode ? null : debugLabel;

  /// Whether or not this [ShadMouseArea] is enabled as part of the composite
  /// region.
  final bool enabled;

  /// How to behave during hit testing when deciding how the hit test propagates
  /// to children and whether to consider targets behind this [ShadMouseArea].
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  ///
  /// See [HitTestBehavior] for the allowed values and their meanings.
  final HitTestBehavior behavior;

  /// {@template ShadMouseArea.groupId}
  /// An optional group ID that groups [ShadMouseArea]s together so that they
  /// operate as one region. If any member of a group is hit by a particular
  /// hover, then all members will have their [onEnter] or [onExit] called.
  ///
  /// If the group id is null, then only this region is hit tested.
  /// {@endtemplate}
  final Object? groupId;

  /// Triggered when a pointer enters the region.
  final PointerEnterEventListener? onEnter;

  /// Triggered when a pointer exits the region.
  final PointerExitEventListener? onExit;

  /// The mouse cursor for mouse pointers that are hovering over the region.
  ///
  /// When a mouse enters the region, its cursor will be changed to the [cursor]
  /// When the mouse leaves the region, the cursor will be decided by the region
  /// found at the new location.
  ///
  /// The [cursor] defaults to [MouseCursor.defer], deferring the choice of
  /// cursor to the next region behind it in hit-test order.
  final MouseCursor cursor;

  /// An optional debug label to help with debugging in debug mode.
  ///
  /// Will be null in release mode.
  final String? debugLabel;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ShadMouseAreaRenderBox(
      registry: MouseAreaRegistry.maybeOf(context),
      enabled: enabled,
      behavior: behavior,
      groupId: groupId,
      debugLabel: debugLabel,
      onEnter: onEnter,
      onExit: onExit,
      cursor: cursor,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'DISABLED',
          defaultValue: true,
        ),
      )
      ..add(
        DiagnosticsProperty<HitTestBehavior>(
          'behavior',
          behavior,
          defaultValue: HitTestBehavior.deferToChild,
        ),
      )
      ..add(
        DiagnosticsProperty<Object?>(
          'debugLabel',
          debugLabel,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null),
      );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant ShadMouseAreaRenderBox renderObject,
  ) {
    renderObject
      ..registry = MouseAreaRegistry.maybeOf(context)
      ..enabled = enabled
      ..behavior = behavior
      ..groupId = groupId
      ..onEnter = onEnter
      ..onExit = onExit;
    if (!kReleaseMode) {
      renderObject.debugLabel = debugLabel;
    }
  }
}

class ShadMouseAreaRenderBox extends RenderProxyBoxWithHitTestBehavior {
  /// Creates a [ShadMouseAreaRenderBox].
  ShadMouseAreaRenderBox({
    this.onEnter,
    this.onExit,
    MouseAreaRegistry? registry,
    bool enabled = true,
    super.behavior = HitTestBehavior.deferToChild,
    bool validForMouseTracker = true,
    Object? groupId,
    String? debugLabel,
    MouseCursor cursor = MouseCursor.defer,
  })  : _registry = registry,
        _cursor = cursor,
        _validForMouseTracker = validForMouseTracker,
        _enabled = enabled,
        _groupId = groupId,
        debugLabel = kReleaseMode ? null : debugLabel;

  bool _isRegistered = false;

  /// A label used in debug builds. Will be null in release builds.
  String? debugLabel;

  bool _enabled;

  Object? _groupId;
  MouseAreaRegistry? _registry;
  bool _validForMouseTracker;

  MouseCursor _cursor;
  PointerEnterEventListener? onEnter;
  PointerExitEventListener? onExit;

  MouseCursor get cursor => _cursor;
  set cursor(MouseCursor value) {
    if (_cursor != value) {
      _cursor = value;
      // A repaint is needed in order to trigger a device update of
      // [MouseTracker] so that this new value can be found.
      markNeedsPaint();
    }
  }

  /// Whether or not this region should participate in the composite region.
  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      markNeedsLayout();
    }
  }

  /// An optional group ID that groups [ShadMouseAreaRenderBox]s together so
  /// that they operate as one region. If any member of a group is hit by a
  /// particular hover, then all members will have their
  /// [onEnter] or [onExit] called.
  ///
  /// If the group id is null, then only this region is hit tested.
  Object? get groupId => _groupId;

  set groupId(Object? value) {
    if (_groupId != value) {
      // If the group changes, we need to unregister and re-register under the
      // new group. The re-registration happens automatically in layout().
      if (_isRegistered) {
        _registry!.unregisterMouseArea(this);
        _isRegistered = false;
      }
      _groupId = value;
      markNeedsLayout();
    }
  }

  /// The registry that this [ShadMouseAreaRenderBox] should register with.
  ///
  /// If the [registry] is null, then this region will not be registered
  /// anywhere, and will not do any tap detection.
  ///
  /// A [MouseAreaSurfaceRenderBox] is a [MouseAreaRegistry].
  MouseAreaRegistry? get registry => _registry;

  set registry(MouseAreaRegistry? value) {
    if (_registry != value) {
      if (_isRegistered) {
        _registry!.unregisterMouseArea(this);
        _isRegistered = false;
      }
      _registry = value;
      markNeedsLayout();
    }
  }

  bool get validForMouseTracker => _validForMouseTracker;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _validForMouseTracker = true;
  }

  @override
  Size computeSizeForNoChild(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<String?>(
          'debugLabel',
          debugLabel,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null),
      )
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'DISABLED',
          defaultValue: true,
        ),
      );
  }

  @override
  void detach() {
    // It's possible that the renderObject be detached during mouse events
    // dispatching, set the [MouseTrackerAnnotation.validForMouseTracker] false
    // to prevent the callbacks from being called.
    _validForMouseTracker = false;
    super.detach();
  }

  @override
  void dispose() {
    if (_isRegistered) {
      _registry!.unregisterMouseArea(this);
    }
    super.dispose();
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    super.layout(constraints, parentUsesSize: parentUsesSize);
    if (_registry == null) {
      return;
    }
    if (_isRegistered) {
      _registry!.unregisterMouseArea(this);
    }
    final shouldBeRegistered = _enabled && _registry != null;
    if (shouldBeRegistered) {
      _registry!.registerMouseArea(this);
    }
    _isRegistered = shouldBeRegistered;
  }
}

/// A widget that provides notification of a hover inside or outside of a set of
/// registered regions, grouped by [ShadMouseArea.groupId], without
/// participating in the [gesture disambiguation](https://flutter.dev/to/gesture-disambiguation) system.
class ShadMouseAreaSurface extends SingleChildRenderObjectWidget {
  /// Creates a const [RenderTapRegionSurface].
  ///
  /// The [child] attribute is required.
  const ShadMouseAreaSurface({
    super.key,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MouseAreaSurfaceRenderBox();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderProxyBoxWithHitTestBehavior renderObject,
  ) {}
}
