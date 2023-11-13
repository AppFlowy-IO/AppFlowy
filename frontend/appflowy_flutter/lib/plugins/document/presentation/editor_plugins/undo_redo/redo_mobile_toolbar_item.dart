import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final redoMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, __) => const FlowySvg(FlowySvgs.m_redo_m),
  actionHandler: (editorState, selection) async {
    editorState.undoManager.redo();
  },
);
