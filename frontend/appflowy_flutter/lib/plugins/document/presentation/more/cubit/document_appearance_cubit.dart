import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDocumentAppearanceFontSize = 'kDocumentAppearanceFontSize';
const String _kDocumentAppearanceFontFamily = 'kDocumentAppearanceFontFamily';

class DocumentAppearance {
  const DocumentAppearance({
    required this.fontSize,
    required this.fontFamily,
  });

  final double fontSize;
  final String fontFamily;
  // Will be supported...
  // final String fontName;

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

  void fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_kDocumentAppearanceFontSize) ?? 16.0;

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize,
      ),
    );
  }

  void syncFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_kDocumentAppearanceFontSize, fontSize);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        fontSize: fontSize,
      ),
    );
  }

  void syncFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_kDocumentAppearanceFontFamily, fontFamily);
    emit(
      state.copyWith(
        fontFamily: fontFamily,
      ),
    );
  }
}
