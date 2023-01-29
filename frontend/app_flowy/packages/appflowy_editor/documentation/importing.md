# Importing data

For now, we have supported three ways to import data to initialize AppFlowy Editor.

1. From AppFlowy Document JSON

```dart
const document = r'''{"document":{"type":"editor","children":[{"type":"text","attributes":{"subtype":"heading","heading":"h1"},"delta":[{"insert":"Hello AppFlowy!"}]}]}}''';
final json = jsonDecode(document);
final editorState = EditorState(
    document: Document.fromJson(
        Map<String, Object>.from(json),
    ),
);
```

2. From Markdown

```dart
const markdown = r'''# Hello AppFlowy!''';
final editorState = EditorState(
    document: markdownToDocument(markdown),
);
```

3. From Quill Delta

```dart
const delta = r'''[{"insert":"Hello AppFlowy!"},{"attributes":{"header":1},"insert":"\n"}]''';
final json = jsonDecode(delta);
final editorState = EditorState(
    document: DeltaDocumentConvert().convertFromJSON(json),
);
```

For more details, please refer to the function `_importFile` through this [link](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/example/lib/home_page.dart).