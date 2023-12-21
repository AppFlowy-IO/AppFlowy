import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';

final boldToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_bold_s,
      onTap: () {},
    );
  },
);

final italicToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_italic_s,
      onTap: () {},
    );
  },
);

final underlineToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_underline_s,
      onTap: () {},
    );
  },
);

final colorToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_color_s,
      onTap: () {},
    );
  },
);
