import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final indentToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      keepSelectedStatus: true,
      isSelected: () => false,
      enable: () => isIndentable(editorState),
      icon: FlowySvgs.m_aa_indent_m,
      onTap: () async {
        indentCommand.execute(editorState);
      },
    );
  },
);

final outdentToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      keepSelectedStatus: true,
      isSelected: () => false,
      enable: () => isOutdentable(editorState),
      icon: FlowySvgs.m_aa_outdent_m,
      onTap: () async {
        outdentCommand.execute(editorState);
      },
    );
  },
);
