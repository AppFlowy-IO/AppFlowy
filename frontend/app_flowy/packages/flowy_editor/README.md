<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

<h1 align="center"><b>FlowyEditor</b></h1>

<p align="center">An easily extensible, test-covered rich text editing component for Flutter</p>


<div align="center">
    <img src="https://raw.githubusercontent.com/LucasXu0/AppFlowy/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/documentation/images/example.png" width = "900"/>
</div>

## Features

* Extensible
    * Support extending custom components.
    * 支持扩展自定义的组件
    * Support extending custom shortcut key parsing
    * 支持扩展自定义快捷键解析
    * Support extending toolbar/popup list(WIP)
    * 支持扩展toolbar/popup list(WIP)
    * ...
* Collaboration Ready
    * All changes to the document are based on **operation**. Theoretically, collaborative editing will be supported in the future.
    * 所有对文档的修改都是基于operation。理论上未来会支持协同编辑。
* Good stability guarantees
    * Current code coverage >= 63%, we will still continue to add more test cases.

> Due to the extensible structure and the increase in functionality, we encourage each commit to add test case code under test to ensure that the other committer does not have to worry about their code affecting the existing logic as much as possible. For more testing information, please check [TESTING.md](https://github.com/LucasXu0/AppFlowy/blob/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/documentation/testing.md)


## Getting started

```shell
flutter pub add flowy_editor
flutter pub get
```

## Usage

Creates editor with empty document
```dart
final editorState = EditorState.empty();
final editor = FlowyEditor(
    editorState: editorState,
    keyEventHandlers: const [],
    customBuilders: const {},
);
```

Creates editor from JSON file
```dart
final json = ...;
final editorState = EditorState(StateTree.fromJson(data));
final editor = FlowyEditor(
    editorState: editorState,
    keyEventHandlers: const [],
    customBuilders: const {},
);
```

For more. Run the example.
```shell
git clone https://github.com/AppFlowy-IO/AppFlowy.git
cd frontend/app_flowy/packages/flowy_editor/example
flutter run
```

## How to extends
### Extending a custom components
Please look at [extending.md](documentation/extending.md) for more details.

## Examples
* Extends a custom component.
    * [Checkbox Text](https://github.com/LucasXu0/AppFlowy/blob/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/lib/src/render/rich_text/checkbox_text.dart) - Showing how to extend new styles based on existing rich text components.
    * [Image](https://github.com/LucasXu0/AppFlowy/blob/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/example/lib/plugin/image_node_widget.dart) - Showing how to extend a new node and render it.
    * More examples. [rich text plugins](https://github.com/LucasXu0/AppFlowy/tree/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/lib/src/render/rich_text)
* Extends a custom shortcut key.
    * [BUIS](https://github.com/LucasXu0/AppFlowy/blob/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/lib/src/service/internal_key_event_handlers/update_text_style_by_command_x_handler.dart) - Showing how to make text bold/underline/italic/strikethrough through shortcut keys
    * [Paste HTML](https://github.com/LucasXu0/AppFlowy/blob/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/lib/src/service/internal_key_event_handlers/copy_paste_handler.dart) - Showing how to handle pasted styles through shortcut keys
    * More examples. [internal key event handlers](https://github.com/LucasXu0/AppFlowy/tree/documentation/flowy_editor/frontend/app_flowy/packages/flowy_editor/lib/src/service/internal_key_event_handlers)

## Glossary
We are working on more detailed instructions, for now please refer to the API documentation.

## Contributing
Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are greatly appreciated. Please look at [CONTRIBUTING.md](documentation/contributing.md) for details.