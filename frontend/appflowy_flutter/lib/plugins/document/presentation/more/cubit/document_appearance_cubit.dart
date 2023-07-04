import 'package:appflowy/core/config/kv_keys.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentAppearance {
  const DocumentAppearance({
    required this.fontSize,
    required this.fontFamily,
  });

  final double fontSize;
  final String fontFamily;

  DocumentAppearance copyWith({
    double? fontSize,
    String? fontFamily,
  }) {
    return DocumentAppearance(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class DocumentAppearanceCubit extends Cubit<DocumentAppearance> {
  DocumentAppearanceCubit()
      : super(const DocumentAppearance(fontSize: 16.0, fontFamily: 'Poppins'));

  Future<void> fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize =
        prefs.getDouble(KVKeys.kDocumentAppearanceFontSize) ?? 16.0;
    final fontFamily =
        prefs.getString(KVKeys.kDocumentAppearanceFontFamily) ?? 'Poppins';

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize,
        fontFamily: fontFamily,
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
}
