import 'package:flutter/material.dart';

class OverlayManager extends StatefulWidget {
  const OverlayManager({Key? key}) : super(key: key);

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
  @override
  Widget build(BuildContext context) {
    Navigator.of(context, rootNavigator: true);
    return Container();
  }
}
