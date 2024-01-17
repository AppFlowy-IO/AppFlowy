import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';

final moreToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_more_s,
      onTap: () {},
    );
  },
);
