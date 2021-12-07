import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

enum AppDisclosureAction {
  rename,
  delete,
}

extension AppDisclosureExtension on AppDisclosureAction {
  String get name {
    switch (this) {
      case AppDisclosureAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case AppDisclosureAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
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
