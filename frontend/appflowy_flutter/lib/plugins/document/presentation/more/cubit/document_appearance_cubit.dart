import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentAppearance {
  const DocumentAppearance({
    required this.fontSize,
    required this.fontFamily,
    this.cursorColor,
    this.selectionColor,
    this.defaultTextDirection,
  });

  final double fontSize;
  final String fontFamily;
  final Color? cursorColor;
  final Color? selectionColor;
  final String? defaultTextDirection;

  /// For nullable fields (like `cursorColor`),
  /// use the corresponding `isNull` flag (like `cursorColorIsNull`) to explicitly set the field to `null`.
  ///
  /// This is necessary because simply passing `null` as the value does not distinguish between wanting to
  /// set the field to `null` and not wanting to update the field at all.
  DocumentAppearance copyWith({
    double? fontSize,
    String? fontFamily,
    Color? cursorColor,
    Color? selectionColor,
    String? defaultTextDirection,
    bool cursorColorIsNull = false,
    bool selectionColorIsNull = false,
    bool textDirectionIsNull = false,
  }) {
    return DocumentAppearance(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      cursorColor: cursorColorIsNull ? null : cursorColor ?? this.cursorColor,
      selectionColor:
          selectionColorIsNull ? null : selectionColor ?? this.selectionColor,
      defaultTextDirection: textDirectionIsNull
          ? null
          : defaultTextDirection ?? this.defaultTextDirection,
    );
  }
}

class DocumentAppearanceCubit extends Cubit<DocumentAppearance> {
  DocumentAppearanceCubit()
      : super(
          const DocumentAppearance(
            fontSize: 16.0,
            fontFamily: builtInFontFamily,
          ),
        );

  Future<void> fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize =
        prefs.getDouble(KVKeys.kDocumentAppearanceFontSize) ?? 16.0;
    final fontFamily = prefs.getString(KVKeys.kDocumentAppearanceFontFamily) ??
        builtInFontFamily;
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

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize,
        fontFamily: fontFamily,
        cursorColor: cursorColor,
        selectionColor: selectionColor,
        defaultTextDirection: defaultTextDirection,
        cursorColorIsNull: cursorColor == null,
        selectionColorIsNull: selectionColor == null,
        textDirectionIsNull: defaultTextDirection == null,
      ),
    );
  }

  Future<void> syncFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(KVKeys.kDocumentAppearanceFontSize, fontSize);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize,
      ),
    );
  }

  Future<void> syncFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(KVKeys.kDocumentAppearanceFontFamily, fontFamily);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontFamily: fontFamily,
      ),
    );
  }

  Future<void> syncDefaultTextDirection(String? direction) async {
    final prefs = await SharedPreferences.getInstance();
    if (direction == null) {
      prefs.remove(KVKeys.kDocumentAppearanceDefaultTextDirection);
    } else {
      prefs.setString(
        KVKeys.kDocumentAppearanceDefaultTextDirection,
        direction,
      );
    }

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        defaultTextDirection: direction,
        textDirectionIsNull: direction == null,
      ),
    );
  }

  Future<void> syncCursorColor(Color? cursorColor) async {
    final prefs = await SharedPreferences.getInstance();

    if (cursorColor == null) {
      prefs.remove(KVKeys.kDocumentAppearanceCursorColor);
    } else {
      prefs.setString(
        KVKeys.kDocumentAppearanceCursorColor,
        cursorColor.toHexString(),
      );
    }

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        cursorColor: cursorColor,
        cursorColorIsNull: cursorColor == null,
      ),
    );
  }

  Future<void> syncSelectionColor(Color? selectionColor) async {
    final prefs = await SharedPreferences.getInstance();

    if (selectionColor == null) {
      prefs.remove(KVKeys.kDocumentAppearanceSelectionColor);
    } else {
      prefs.setString(
        KVKeys.kDocumentAppearanceSelectionColor,
        selectionColor.toHexString(),
      );
    }

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        selectionColor: selectionColor,
        selectionColorIsNull: selectionColor == null,
      ),
    );
  }
}
