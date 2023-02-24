import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('delta_markdown_encoder.dart', () {
    test('bold', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.bold: true,
        }),
      ]);
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(result, 'Welcome to **AppFlowy**');
    });

    test('italic', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.italic: true,
        }),
      ]);
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(result, 'Welcome to _AppFlowy_');
    });

    test('underline', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.underline: true,
        }),
      ]);
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(result, 'Welcome to <u>AppFlowy</u>');
    });

    test('strikethrough', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.strikethrough: true,
        }),
      ]);
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(result, 'Welcome to ~~AppFlowy~~');
    });

    test('href', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.href: 'https://appflowy.io',
        }),
      ]);
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(result, 'Welcome to [AppFlowy](https://appflowy.io)');
    });

    test('code', () {
      final delta = Delta(operations: [
        TextInsert('Welcome to '),
        TextInsert('AppFlowy', attributes: {
          BuiltInAttributeKey.code: true,
        }),
      ]);
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(result, 'Welcome to `AppFlowy`');
    });

    test('composition', () {
      final delta = Delta(operations: [
        TextInsert('Welcome', attributes: {
          BuiltInAttributeKey.code: true,
          BuiltInAttributeKey.italic: true,
          BuiltInAttributeKey.bold: true,
          BuiltInAttributeKey.underline: true,
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
      final result = DeltaMarkdownEncoder().convert(delta);
      expect(
        result,
        '***<u>`Welcome`</u>*** ***~~to~~*** ***[AppFlowy](https://appflowy.io)***',
      );
    });
  });
}
