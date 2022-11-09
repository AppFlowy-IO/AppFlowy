import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('delta_markdown_decoder.dart', () {
    test('bold', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.bold: true,
        }),
      ]);
      final result = DeltaMarkdownDecoder().convert('Welcome to **AppFlowy**');
      expect(result, delta);
    });

    test('italic', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.italic: true,
        }),
      ]);
      final result = DeltaMarkdownDecoder().convert('Welcome to _AppFlowy_');
      expect(result, delta);
    });

    test('strikethrough', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.strikethrough: true,
        }),
      ]);
      final result = DeltaMarkdownDecoder().convert('Welcome to ~~AppFlowy~~');
      expect(result, delta);
    });

    test('href', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.href: 'https://appflowy.io',
        }),
      ]);
      final result = DeltaMarkdownDecoder()
          .convert('Welcome to [AppFlowy](https://appflowy.io)');
      expect(result, delta);
    });

    test('code', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.code: true,
        }),
      ]);
      final result = DeltaMarkdownDecoder().convert('Welcome to `AppFlowy`');
      expect(result, delta);
    });

    test('bold', () {
      const markdown =
          '***<u>`Welcome`</u>*** ***~~to~~*** ***[AppFlowy](https://appflowy.io)***';
      final delta = Delta(operations: [
        TextInsert('<u>', attributes: {
          BuiltInAttributeKey.italic: true,
          BuiltInAttributeKey.bold: true,
        }),
        TextInsert('Welcome', attributes: {
          BuiltInAttributeKey.code: true,
          BuiltInAttributeKey.italic: true,
          BuiltInAttributeKey.bold: true,
        }),
        TextInsert('</u>', attributes: {
          BuiltInAttributeKey.italic: true,
          BuiltInAttributeKey.bold: true,
        }),
        TextInsert(' '),
        TextInsert('to', attributes: {
          BuiltInAttributeKey.italic: true,
          BuiltInAttributeKey.bold: true,
          BuiltInAttributeKey.strikethrough: true,
        }),
        TextInsert(' '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.href: 'https://appflowy.io',
          BuiltInAttributeKey.bold: true,
          BuiltInAttributeKey.italic: true,
        }),
      ]);
      final result = DeltaMarkdownDecoder().convert(markdown);
      expect(result, delta);
    });
  });
}
