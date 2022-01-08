import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

enum ViewDisclosureAction {
  rename,
  delete,
  duplicate,
}

extension ViewDisclosureExtension on ViewDisclosureAction {
  String get name {
    switch (this) {
      case ViewDisclosureAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case ViewDisclosureAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
      case ViewDisclosureAction.duplicate:
        return LocaleKeys.disclosureAction_duplicate.tr();
    }
  }

  Widget get icon {
    switch (this) {
      case ViewDisclosureAction.rename:
        return svg('editor/edit', color: const Color(0xffa1a1a1));
      case ViewDisclosureAction.delete:
        return svg('editor/delete', color: const Color(0xffa1a1a1));
      case ViewDisclosureAction.duplicate:
        return svg('editor/copy', color: const Color(0xffa1a1a1));
    }
  }
}
