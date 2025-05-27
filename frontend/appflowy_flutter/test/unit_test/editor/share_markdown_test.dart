import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/document_markdown_parsers.dart';
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
                    "formula":"E = MC^2"
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

    test('code block', () {
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"code",
                "data":{
                      "delta": [
                        {
                            "insert": "Some Code"
                        }
                    ]
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

    test('callout', () {
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"callout",
                "data":{
                    "icon": "😁",
                    "delta": [
                        {
                            "insert": "Callout"
                        }
                    ]
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
          const CalloutNodeParser(),
        ],
      );
      expect(result, '''> 😁
> Callout

''');
    });

    test('toggle list', () {
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"toggle_list",
                "data":{
                    "delta": [
                        {
                            "insert": "Toggle list"
                        }
                    ]
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
          const ToggleListNodeParser(),
        ],
      );
      expect(result, '- Toggle list\n');
    });

    test('custom image', () {
      const image =
          'https://images.unsplash.com/photo-1694984121999-36d30b67f391?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwzfHx8ZW58MHx8fHx8&auto=format&fit=crop&w=800&q=60';
      const text = '''
{
    "document":{
        "type":"page",
        "children":[
            {
                "type":"image",
                "data":{
                    "url": "$image"
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
          const CustomImageNodeParser(),
        ],
      );
      expect(
        result,
        '![]($image)\n',
      );
    });
  });
}
