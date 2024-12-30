import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';

extension GetIcon on SearchResultPB {
  Widget? getIcon() {
    if (icon.ty == ResultIconTypePB.Emoji) {
      return icon.value.isNotEmpty
          ? Text(
              icon.value,
              style: const TextStyle(fontSize: 18.0),
            )
          : null;
    } else if (icon.ty == ResultIconTypePB.Icon) {
      return FlowySvg(icon.getViewSvg(), size: const Size.square(20));
    }

    return null;
  }
}

extension _ToViewIcon on ResultIconPB {
  FlowySvgData getViewSvg() => switch (value) {
        "0" => FlowySvgs.icon_document_s,
        "1" => FlowySvgs.icon_grid_s,
        "2" => FlowySvgs.icon_board_s,
        "3" => FlowySvgs.icon_calendar_s,
        _ => FlowySvgs.icon_document_s,
      };
}
