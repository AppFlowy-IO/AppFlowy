import 'dart:convert';

import 'package:app_flowy/plugins/document/presentation/plugins/parsers/divider_node_parser.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/parsers/math_equation_node_parser.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('share markdown', () {
    test('math equation', () {
      const text = '''
{
    "document":{
        "type":"editor",
        "children":[
            {
                "type":"math_equation",
                "attributes":{
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
      final result = documentToMarkdown(document, customParsers: [
        const MathEquationNodeParser(),
      ]);
      expect(result, r'$$E = MC^2$$');
    });

    test('divider', () {
      const text = '''
{
    "document":{
        "type":"editor",
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
      final result = documentToMarkdown(document, customParsers: [
        const DividerNodeParser(),
      ]);
      expect(result, '---\n');
    });
  });
}
