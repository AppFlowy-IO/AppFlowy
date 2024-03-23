import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentAppearanceCubit extends Mock
    implements DocumentAppearanceCubit {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  group('EditorStyleCustomizer', () {
    late EditorStyleCustomizer editorStyleCustomizer;
    late MockBuildContext mockBuildContext;

    setUp(() {
      mockBuildContext = MockBuildContext();
      editorStyleCustomizer = EditorStyleCustomizer(
        context: mockBuildContext,
        padding: EdgeInsets.zero,
      );
    });

    test('baseTextStyle should return the expected TextStyle', () {
      const fontFamily = 'Roboto';
      final result = editorStyleCustomizer.baseTextStyle(fontFamily);
      expect(result, isA<TextStyle>());
      expect(result.fontFamily, 'Roboto_regular');
    });

    test(
        'baseTextStyle should return the default TextStyle when an exception occurs',
        () {
      const garbage = 'Garbage';
      final result = editorStyleCustomizer.baseTextStyle(garbage);
      expect(result, isA<TextStyle>());
      expect(
        result.fontFamily,
        GoogleFonts.getFont(builtInFontFamily).fontFamily,
      );
    });
  });
}
