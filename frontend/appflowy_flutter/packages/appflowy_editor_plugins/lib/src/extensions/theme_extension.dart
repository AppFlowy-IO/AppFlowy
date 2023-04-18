import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

extension FlowyTintExtension on FlowyTint {
  String tintName(
    AppFlowyEditorLocalizations l10n, {
    ThemeMode? themeMode,
    String? theme,
  }) {
    switch (this) {
      case FlowyTint.tint1:
        return l10n.lightLightTint1;
      case FlowyTint.tint2:
        return l10n.lightLightTint2;
      case FlowyTint.tint3:
        return l10n.lightLightTint3;
      case FlowyTint.tint4:
        return l10n.lightLightTint4;
      case FlowyTint.tint5:
        return l10n.lightLightTint5;
      case FlowyTint.tint6:
        return l10n.lightLightTint6;
      case FlowyTint.tint7:
        return l10n.lightLightTint7;
      case FlowyTint.tint8:
        return l10n.lightLightTint8;
      case FlowyTint.tint9:
        return l10n.lightLightTint9;
    }
  }
}
