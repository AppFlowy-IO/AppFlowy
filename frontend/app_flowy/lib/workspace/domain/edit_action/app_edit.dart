import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

enum AppDisclosureAction {
  rename,
  delete,
}

extension AppDisclosureExtension on AppDisclosureAction {
  String get name {
    switch (this) {
      case AppDisclosureAction.rename:
        return 'rename';
      case AppDisclosureAction.delete:
        return 'delete';
    }
  }

  Widget get icon {
    switch (this) {
      case AppDisclosureAction.rename:
        return svg('editor/edit');
      case AppDisclosureAction.delete:
        return svg('editor/delete');
    }
  }
}
