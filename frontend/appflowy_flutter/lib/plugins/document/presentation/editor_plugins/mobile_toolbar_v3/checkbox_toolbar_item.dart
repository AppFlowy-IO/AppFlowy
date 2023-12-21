import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';

final checkboxToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_checkbox_s,
      onTap: () {},
    );
  },
);
