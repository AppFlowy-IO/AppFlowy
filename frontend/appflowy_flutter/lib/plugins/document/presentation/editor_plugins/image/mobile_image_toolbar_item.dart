import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final imageMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, __, ___) => const FlowySvg(FlowySvgs.m_toolbar_imae_lg),
  actionHandler: (_, editorState) async {
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await editorState.insertEmptyImageBlock(imagePlaceholderKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      imagePlaceholderKey.currentState?.showUploadImageMenu();
    });
  },
);
