import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';


extension MobileSearchIconItemExtension on ResultIconPB {
  Widget? buildIcon(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    if (ty == ResultIconTypePB.Emoji) {
      return SizedBox(
        width: 20,
        child: getIcon(size: 20) ?? SizedBox.shrink(),
      );
    } else {
      return getIcon(
            size: 20,
            iconColor: theme.iconColorScheme.secondary,
          ) ??
          SizedBox.shrink();
    }
  }
}
