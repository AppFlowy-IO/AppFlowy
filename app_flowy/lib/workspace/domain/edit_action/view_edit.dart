import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

enum ViewDisclosureAction {
  rename,
  delete,
  duplicate,
}

extension ViewDisclosureExtension on ViewDisclosureAction {
  String get name {
    switch (this) {
      case ViewDisclosureAction.rename:
        return 'Rename';
      case ViewDisclosureAction.delete:
        return 'Delete';
      case ViewDisclosureAction.duplicate:
        return 'Duplicate';
    }
  }

  Widget get icon {
    switch (this) {
      case ViewDisclosureAction.rename:
        return svg('editor/edit');
      case ViewDisclosureAction.delete:
        return svg('editor/delete');
      case ViewDisclosureAction.duplicate:
        return svg('editor/copy');
    }
  }
}
