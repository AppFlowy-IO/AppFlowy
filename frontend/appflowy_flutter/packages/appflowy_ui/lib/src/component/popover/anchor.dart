import 'package:appflowy_ui/src/component/popover/shadcn/_portal.dart';
import 'package:flutter/material.dart';

/// Automatically infers the position of the [ShadPortal] in the global
/// coordinate system adjusting according to the [offset],
/// [followerAnchor] and [targetAnchor] properties.
@immutable
class AFAnchorAuto extends ShadAnchorAuto {
  const AFAnchorAuto({
    super.offset,
    super.followTargetOnResize,
    super.followerAnchor,
    super.targetAnchor,
  });
}

/// Manually specifies the position of the [ShadPortal] in the global
/// coordinate system.
@immutable
class AFAnchor extends ShadAnchor {
  const AFAnchor({
    super.childAlignment,
    super.overlayAlignment,
    super.offset,
  });
}

/// Manually specifies the position of the [ShadPortal] in the global
/// coordinate system.
@immutable
class AFGlobalAnchor extends ShadGlobalAnchor {
  const AFGlobalAnchor(super.offset);
}
