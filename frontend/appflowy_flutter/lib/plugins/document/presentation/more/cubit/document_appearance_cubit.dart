import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentAppearance {
  const DocumentAppearance({
    required this.fontSize,
    required this.fontFamily,
    this.defaultTextDirection,
  });

  final double fontSize;
  final String fontFamily;
  final String? defaultTextDirection;

  DocumentAppearance copyWith({
    double? fontSize,
    String? fontFamily,
    String? defaultTextDirection,
  }) {
    return DocumentAppearance(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
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

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize,
        fontFamily: fontFamily,
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
}
