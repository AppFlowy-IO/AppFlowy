import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDocumentAppearanceFontSize = 'kDocumentAppearanceFontSize';

class DocumentAppearance {
  const DocumentAppearance({
    required this.fontSize,
  });

  final double fontSize;
  // Will be supported...
  // final String fontName;

  DocumentAppearance copyWith({double? fontSize}) {
    return DocumentAppearance(
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class DocumentAppearanceCubit extends Cubit<DocumentAppearance> {
  DocumentAppearanceCubit() : super(const DocumentAppearance(fontSize: 16.0));

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
}
