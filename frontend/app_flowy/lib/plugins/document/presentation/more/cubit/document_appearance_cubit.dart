import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDocumentAppearenceFontSize = 'kDocumentAppearenceFontSize';

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
  DocumentAppearanceCubit() : super(const DocumentAppearance(fontSize: 14.0)) {
    fetch();
  }

  late DocumentAppearance documentAppearance;

  void fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_kDocumentAppearenceFontSize) ?? 14.0;
    documentAppearance = DocumentAppearance(fontSize: fontSize);
    emit(documentAppearance);
  }

  void sync(DocumentAppearance documentAppearance) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_kDocumentAppearenceFontSize, documentAppearance.fontSize);
    this.documentAppearance = documentAppearance;
    emit(documentAppearance);
  }
}
