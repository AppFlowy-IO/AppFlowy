import 'package:flutter/material.dart';

import 'overlay_hittest.dart';

final GlobalKey<OverlayManagerState> _key = GlobalKey<OverlayManagerState>();

/// Invoke this method in app generation process
TransitionBuilder overlayManagerBuilder() {
  return (context, child) {
    return OverlayManager(key: _key, child: child);
  };
}

class OverlayManager extends StatefulWidget {
  const OverlayManager({Key? key, required this.child}) : super(key: key);

  final Widget? child;

  static OverlayManagerState of(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    OverlayManagerState? overlayManager;
    if (rootOverlay) {
      overlayManager = context.findRootAncestorStateOfType<OverlayManagerState>() ?? overlayManager;
    } else {
      overlayManager = overlayManager ?? context.findAncestorStateOfType<OverlayManagerState>();
    }

    assert(() {
      if (overlayManager == null) {
        throw FlutterError(
          'Can\'t find overlay manager in current context, please check if already wrapped by overlay manager.',
        );
      }
      return true;
    }());
    return overlayManager!;
  }

  static OverlayManagerState? maybeOf(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    OverlayManagerState? overlayManager;
    if (rootOverlay) {
      overlayManager = context.findRootAncestorStateOfType<OverlayManagerState>() ?? overlayManager;
    } else {
      overlayManager = overlayManager ?? context.findAncestorStateOfType<OverlayManagerState>();
    }

    return overlayManager;
  }

  @override
  OverlayManagerState createState() => OverlayManagerState();
}

class OverlayManagerState extends State<OverlayManager> {
  final Map<String, Map<String, OverlayEntry>> _overlayEntrys = {};

  void insert(Widget widget, String featureKey, String key) {
    final overlay = Overlay.of(context);
    assert(overlay != null);

    final entry = OverlayEntry(builder: (_) => widget);
    _overlayEntrys[featureKey] ??= {};
    _overlayEntrys[featureKey]![key] = entry;
    overlay!.insert(entry);
  }

  void insertAll(List<Widget> widgets, String featureKey, List<String> keys) {
    assert(widgets.isNotEmpty);
    assert(widgets.length == keys.length);

    final overlay = Overlay.of(context);
    assert(overlay != null);

    List<OverlayEntry> entries = [];
    _overlayEntrys[featureKey] ??= {};
    for (int idx = 0; idx < widgets.length; idx++) {
      final entry = OverlayEntry(builder: (_) => widget);
      entries.add(entry);
      _overlayEntrys[featureKey]![keys[idx]] = entry;
    }
    overlay!.insertAll(entries);
  }

  void remove(String featureKey, String key) {
    if (_overlayEntrys.containsKey(featureKey)) {
      final entry = _overlayEntrys[featureKey]!.remove(key);
      entry?.remove();
    }
  }

  void removeAll(String featureKey) {
    if (_overlayEntrys.containsKey(featureKey)) {
      final entries = _overlayEntrys.remove(featureKey);
      entries?.forEach((_, overlay) {
        overlay.remove();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.child != null);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: OverlayHitTestArea(child: widget.child),
    );
  }
}
