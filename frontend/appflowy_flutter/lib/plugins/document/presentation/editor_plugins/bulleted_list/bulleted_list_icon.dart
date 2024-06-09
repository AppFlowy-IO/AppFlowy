import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BulletedListIcon extends StatelessWidget {
  const BulletedListIcon({
    super.key,
    required this.node,
  });

  final Node node;

  static final bulletedListIcons = [
    FlowySvgs.bulleted_list_icon_1_s,
    FlowySvgs.bulleted_list_icon_2_s,
    FlowySvgs.bulleted_list_icon_3_s,
  ];

  int get level {
    var level = 0;
    var parent = node.parent;
    while (parent != null) {
      if (parent.type == BulletedListBlockKeys.type) {
        level++;
      }
      parent = parent.parent;
    }
    return level;
  }

  FlowySvg get icon {
    final index = level % bulletedListIcons.length;
    return FlowySvg(bulletedListIcons[index]);
  }

  @override
  Widget build(BuildContext context) {
    final iconPadding = PlatformExtension.isMobile
        ? context.read<DocumentPageStyleBloc>().state.iconPadding
        : 0.0;
    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      margin: EdgeInsets.only(top: iconPadding, right: 8.0),
      child: icon,
    );
  }
}
