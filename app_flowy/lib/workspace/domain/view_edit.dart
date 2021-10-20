import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

enum ViewAction {
  rename,
  delete,
  duplicate,
}

extension ViewActionExtension on ViewAction {
  String get name {
    switch (this) {
      case ViewAction.rename:
        return 'rename';
      case ViewAction.delete:
        return 'delete';
      case ViewAction.duplicate:
        return 'duplicate';
    }
  }

  Widget get icon {
    switch (this) {
      case ViewAction.rename:
        return svg('editor/edit');
      case ViewAction.delete:
        return svg('editor/delete');
      case ViewAction.duplicate:
        return svg('editor/copy');
    }
  }
}
