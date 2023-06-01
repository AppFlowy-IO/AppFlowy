import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/code_block_node_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/divider_node_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/math_equation_node_parser.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('share markdown', () {
    test('math equation', () {
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"math_equation",
                "data":{
                    "math_equation":"E = MC^2"
                }
            }
        ]
    }
}
''';
      final document = Document.fromJson(
        Map<String, Object>.from(json.decode(text)),
      );
      final result = documentToMarkdown(
        document,
        customParsers: [
          const MathEquationNodeParser(),
        ],
      );
      expect(result, r'$$E = MC^2$$');
    });
    // Changes
    test('code block', () {
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"code_block",
                "data":{
                    "code_block":"Some Code"
                }
            }
        ]
    }
}
''';
      final document = Document.fromJson(
        Map<String, Object>.from(json.decode(text)),
      );
      final result = documentToMarkdown(
        document,
        customParsers: [
          const CodeBlockNodeParser(),
        ],
      );
      expect(result, '```\nSome Code\n```');
    });
    test('divider', () {
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"divider"
            }
        ]
    }
}
''';
      final document = Document.fromJson(
        Map<String, Object>.from(json.decode(text)),
      );
      final result = documentToMarkdown(
        document,
        customParsers: [
          const DividerNodeParser(),
        ],
      );
      expect(result, '---\n');
    });
  });
}
