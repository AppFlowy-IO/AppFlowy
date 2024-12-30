import 'dart:async';

import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

class DocumentAppearance {
  const DocumentAppearance({
    required this.fontSize,
    required this.fontFamily,
    required this.codeFontFamily,
    required this.width,
    this.cursorColor,
    this.selectionColor,
    this.defaultTextDirection,
  });

  final double fontSize;
  final String fontFamily;
  final String codeFontFamily;
  final Color? cursorColor;
  final Color? selectionColor;
  final String? defaultTextDirection;
  final double width;

  /// For nullable fields (like `cursorColor`),
  /// use the corresponding `isNull` flag (like `cursorColorIsNull`) to explicitly set the field to `null`.
  ///
  /// This is necessary because simply passing `null` as the value does not distinguish between wanting to
  /// set the field to `null` and not wanting to update the field at all.
  DocumentAppearance copyWith({
    double? fontSize,
    String? fontFamily,
    String? codeFontFamily,
    Color? cursorColor,
    Color? selectionColor,
    String? defaultTextDirection,
    bool cursorColorIsNull = false,
    bool selectionColorIsNull = false,
    bool textDirectionIsNull = false,
    double? width,
  }) {
    return DocumentAppearance(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      codeFontFamily: codeFontFamily ?? this.codeFontFamily,
      cursorColor: cursorColorIsNull ? null : cursorColor ?? this.cursorColor,
      selectionColor:
          selectionColorIsNull ? null : selectionColor ?? this.selectionColor,
      defaultTextDirection: textDirectionIsNull
          ? null
          : defaultTextDirection ?? this.defaultTextDirection,
      width: width ?? this.width,
    );
  }
}

class DocumentAppearanceCubit extends Cubit<DocumentAppearance> {
  DocumentAppearanceCubit()
      : super(
          DocumentAppearance(
            fontSize: 16.0,
            fontFamily: defaultFontFamily,
            codeFontFamily: builtInCodeFontFamily,
            width: UniversalPlatform.isMobile
                ? double.infinity
                : EditorStyleCustomizer.maxDocumentWidth,
          ),
        );

  Future<void> fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize =
        prefs.getDouble(KVKeys.kDocumentAppearanceFontSize) ?? 16.0;
    final fontFamily = prefs.getString(KVKeys.kDocumentAppearanceFontFamily) ??
        defaultFontFamily;
    final defaultTextDirection =
        prefs.getString(KVKeys.kDocumentAppearanceDefaultTextDirection);

    final cursorColorString =
        prefs.getString(KVKeys.kDocumentAppearanceCursorColor);
    final selectionColorString =
        prefs.getString(KVKeys.kDocumentAppearanceSelectionColor);
    final cursorColor =
        cursorColorString != null ? Color(int.parse(cursorColorString)) : null;
    final selectionColor = selectionColorString != null
        ? Color(int.parse(selectionColorString))
        : null;
    final double? width = prefs.getDouble(KVKeys.kDocumentAppearanceWidth);

    final textScaleFactor =
        double.parse(prefs.getString(KVKeys.textScaleFactor) ?? '1.0');

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize * textScaleFactor,
        fontFamily: fontFamily,
        cursorColor: cursorColor,
        selectionColor: selectionColor,
        defaultTextDirection: defaultTextDirection,
        cursorColorIsNull: cursorColor == null,
        selectionColorIsNull: selectionColor == null,
        textDirectionIsNull: defaultTextDirection == null,
        width: width,
      ),
    );
  }

  Future<void> syncFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(KVKeys.kDocumentAppearanceFontSize, fontSize);

    if (!isClosed) {
      emit(state.copyWith(fontSize: fontSize));
    }
  }

  Future<void> syncFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KVKeys.kDocumentAppearanceFontFamily, fontFamily);

    if (!isClosed) {
      emit(state.copyWith(fontFamily: fontFamily));
    }
  }

  Future<void> syncDefaultTextDirection(String? direction) async {
    final prefs = await SharedPreferences.getInstance();
    if (direction == null) {
      await prefs.remove(KVKeys.kDocumentAppearanceDefaultTextDirection);
    } else {
      await prefs.setString(
        KVKeys.kDocumentAppearanceDefaultTextDirection,
        direction,
      );
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          defaultTextDirection: direction,
          textDirectionIsNull: direction == null,
        ),
      );
    }
  }

  Future<void> syncCursorColor(Color? cursorColor) async {
    final prefs = await SharedPreferences.getInstance();

    if (cursorColor == null) {
      await prefs.remove(KVKeys.kDocumentAppearanceCursorColor);
    } else {
      await prefs.setString(
        KVKeys.kDocumentAppearanceCursorColor,
        cursorColor.toHexString(),
      );
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          cursorColor: cursorColor,
          cursorColorIsNull: cursorColor == null,
        ),
      );
    }
  }

  Future<void> syncSelectionColor(Color? selectionColor) async {
    final prefs = await SharedPreferences.getInstance();

    if (selectionColor == null) {
      await prefs.remove(KVKeys.kDocumentAppearanceSelectionColor);
    } else {
      await prefs.setString(
        KVKeys.kDocumentAppearanceSelectionColor,
        selectionColor.toHexString(),
      );
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          selectionColor: selectionColor,
          selectionColorIsNull: selectionColor == null,
        ),
      );
    }
  }

  Future<void> syncWidth(double? width) async {
    final prefs = await SharedPreferences.getInstance();

    width ??= UniversalPlatform.isMobile
        ? double.infinity
        : EditorStyleCustomizer.maxDocumentWidth;
    width = width.clamp(
      EditorStyleCustomizer.minDocumentWidth,
      EditorStyleCustomizer.maxDocumentWidth,
    );
    await prefs.setDouble(KVKeys.kDocumentAppearanceWidth, width);

    if (!isClosed) {
      emit(state.copyWith(width: width));
    }
  }
}
