import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
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

  DocumentAppearance copyWith({
    double? fontSize,
    String? fontFamily,
    String? defaultTextDirection,
    Color? cursorColor,
    Color? selectionColor,
  }) {
    return DocumentAppearance(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      cursorColor: cursorColor,
      selectionColor: selectionColor,
      defaultTextDirection: defaultTextDirection,
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
    print('debug1 fetch cursorColorString : $cursorColorString');
    print('debug1 fetch selectionColorString: $selectionColorString');
    final cursorColor = cursorColorString == null
        ? null
        : Color(
            int.parse(
              cursorColorString,
            ),
          );
    final selectionColor = selectionColorString == null
        ? null
        : Color(
            int.parse(
              selectionColorString,
            ),
          );

    // final selectionColor = await getSelectionColorFromBackend();
    // final cursorColor = await getCursorColorFromBackend();

    if (isClosed) {
      return;
    }
    print('debug1 sharedPref fetch cursorColor: $cursorColor');
    print('debug1 sharedPref fetch selectionColor: $selectionColor');

    emit(
      state.copyWith(
        fontSize: fontSize,
        fontFamily: fontFamily,
        cursorColor: cursorColor,
        selectionColor: selectionColor,
        defaultTextDirection: defaultTextDirection,
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
    print(
      'debug1 sharedPref syncCursorColor: ${cursorColor?.toHexString()}',
    );
    emit(
      state.copyWith(
        cursorColor: cursorColor,
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

    print(
      'debug1  sharedPref s syncSelectionColor ${selectionColor?.toHexString()}',
    );

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        selectionColor: selectionColor,
      ),
    );
  }
}




// Future<Color?> getSelectionColorFromBackend() async {
//   final appearanceSetting =
//       await UserSettingsBackendService().getAppearanceSetting();
//   final selectionColor =
//       appearanceSetting.documentSetting.selectionColor.isEmpty
//           ? null
//           : Color(
//               int.parse(
//                 appearanceSetting.documentSetting.selectionColor,
//               ),
//             );

//   return selectionColor;
// }

// Future<Color?> getCursorColorFromBackend() async {
//   final appearanceSetting =
//       await UserSettingsBackendService().getAppearanceSetting();
//   final cursorColor = appearanceSetting.documentSetting.cursorColor.isEmpty
//       ? null
//       : Color(
//           int.parse(
//             appearanceSetting.documentSetting.cursorColor,
//           ),
//         );

//   return cursorColor;
// }
