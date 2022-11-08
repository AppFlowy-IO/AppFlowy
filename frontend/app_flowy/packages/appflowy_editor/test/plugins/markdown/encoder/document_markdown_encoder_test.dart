import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('document_markdown_encoder.dart', () {
    const example = '''
{
  "document": {
    "type": "editor",
    "children": [
      {
        "type": "text",
        "attributes": {
          "subtype": "heading",
          "heading": "h2"
        },
        "delta": [
          { "insert": "👋 " },
          { "insert": "Welcome to", "attributes": { "bold": true } },
          { "insert": " " },
          {
            "insert": "AppFlowy Editor",
            "attributes": {
              "href": "appflowy.io",
              "italic": true,
              "bold": true
            }
          }
        ]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "delta": [
          { "insert": "AppFlowy Editor is a " },
          { "insert": "highly customizable", "attributes": { "bold": true } },
          { "insert": " " },
          { "insert": "rich-text editor", "attributes": { "italic": true } },
          { "insert": " for " },
          { "insert": "Flutter", "attributes": { "underline": true } }
        ]
      },
      {
        "type": "text",
        "attributes": { "checkbox": true, "subtype": "checkbox" },
        "delta": [{ "insert": "Customizable" }]
      },
      {
        "type": "text",
        "attributes": { "checkbox": true, "subtype": "checkbox" },
        "delta": [{ "insert": "Test-covered" }]
      },
      {
        "type": "text",
        "attributes": { "checkbox": false, "subtype": "checkbox" },
        "delta": [{ "insert": "more to come!" }]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "attributes": { "subtype": "quote" },
        "delta": [{ "insert": "Here is an example you can give a try" }]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "delta": [
          { "insert": "You can also use " },
          {
            "insert": "AppFlowy Editor",
            "attributes": {
              "italic": true,
              "bold": true,
              "backgroundColor": "0x6000BCF0"
            }
          },
          { "insert": " as a component to build your own app." }
        ]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "attributes": { "subtype": "bulleted-list" },
        "delta": [{ "insert": "Use / to insert blocks" }]
      },
      {
        "type": "text",
        "attributes": { "subtype": "bulleted-list" },
        "delta": [
          {
            "insert": "Select text to trigger to the toolbar to format your notes."
          }
        ]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "delta": [
          {
            "insert": "If you have questions or feedback, please submit an issue on Github or join the community along with 1000+ builders!"
          }
        ]
      }
    ]
  }
}
''';
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('parser document', () async {
      final data = Map<String, Object>.from(json.decode(example));
      final document = Document.fromJson(data);
      final result = DocumentMarkdownEncoder().convert(document);
      expect(result, '''
## 👋 **Welcome to** ***[AppFlowy Editor](appflowy.io)***

AppFlowy Editor is a **highly customizable** _rich-text editor_ for <u>Flutter</u>
- [x] Customizable
- [x] Test-covered
- [ ] more to come!

> Here is an example you can give a try

You can also use ***AppFlowy Editor*** as a component to build your own app.

* Use / to insert blocks
* Select text to trigger to the toolbar to format your notes.

If you have questions or feedback, please submit an issue on Github or join the community along with 1000+ builders!
''');
    });
  });
}
