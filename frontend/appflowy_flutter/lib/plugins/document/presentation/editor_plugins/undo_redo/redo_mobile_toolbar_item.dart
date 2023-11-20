import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final redoMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, __, ___) => const FlowySvg(
    FlowySvgs.m_redo_m,
  ),
  actionHandler: (_, editorState) async {
    editorState.undoManager.redo();
  },
);
