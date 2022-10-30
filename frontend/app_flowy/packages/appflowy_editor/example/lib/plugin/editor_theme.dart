import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData customizeEditorTheme(BuildContext context) {
  final dark = EditorStyle.dark;
  final editorStyle = dark.copyWith(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 150),
    cursorColor: Colors.red.shade600,
    selectionColor: Colors.yellow.shade600.withOpacity(0.5),
    textStyle: GoogleFonts.poppins().copyWith(
      fontSize: 14,
      color: Colors.white,
    ),
    placeholderTextStyle: GoogleFonts.poppins().copyWith(
      fontSize: 14,
      color: Colors.grey.shade400,
    ),
    code: dark.code?.copyWith(
      backgroundColor: Colors.lightBlue.shade200,
      fontStyle: FontStyle.italic,
    ),
    highlightColorHex: '0x60FF0000', // red
  );

  final quote = QuotedTextPluginStyle.dark.copyWith(
    textStyle: (_, __) => GoogleFonts.poppins().copyWith(
      fontSize: 14,
      color: Colors.blue.shade400,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
    ),
  );

  return Theme.of(context).copyWith(extensions: [
    editorStyle,
    ...darkPlguinStyleExtension,
    quote,
  ]);
}
