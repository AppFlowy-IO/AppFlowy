import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

TextDirection getTextDirectionBaseOnContext(
  BuildContext context,
  String text, {
  TextDirection? lastDirection,
}) {
  return getTextDirection(
    context.read<AppearanceSettingsCubit>().state.textDirection,
    text,
    layoutDirection:
        context.read<AppearanceSettingsCubit>().state.layoutDirection,
    lastDirection: lastDirection,
  );
}

// Return flowyDirection if its not auto. If its auto
// determine the text direction based on text or fallback to
// 1. lastDirection
// 2. layoutDirection
// 3. LTR
TextDirection getTextDirection(
  AppFlowyTextDirection? flowyDirection,
  String text, {
  LayoutDirection? layoutDirection,
  TextDirection? lastDirection,
}) {
  var fallbackDirection = layoutDirection == LayoutDirection.rtlLayout
      ? TextDirection.rtl
      : TextDirection.ltr;
  fallbackDirection = lastDirection ?? fallbackDirection;

  switch (flowyDirection) {
    case AppFlowyTextDirection.auto:
      return determineTextDirection(text) ?? fallbackDirection;
    case AppFlowyTextDirection.rtl:
      return TextDirection.rtl;
    case AppFlowyTextDirection.ltr:
    default:
      return TextDirection.ltr;
  }
}
