import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final undoMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, __) => const FlowySvg(FlowySvgs.m_undo_m),
  actionHandler: (editorState, selection) async {
    editorState.undoManager.undo();
  },
);
