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

<h1 align="center"><b>AppFlowy Editor</b></h1>

<p align="center">A highly customizable rich-text editor for Flutter</p>

<p align="center">
    <a href="https://discord.gg/ZCCYN4Anzq"><b>Discord</b></a> •
    <a href="https://twitter.com/appflowy"><b>Twitter</b></a>
</p>

<div align="center">
    <img src="https://i.ibb.co/HNnc1jP/appflowy-editor-example.gif" width = "900"/>
</div>

## Key Features

* Allow you to build rich, intuitive editors
* Design and modify it your way by customizing components, shortcut events, and many more coming soon including menu options and themes
* [Test-covered](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/testing.md) and maintained by AppFlowy's core team along with a community of more than 1,000 builders


## Getting started

```shell
flutter pub add appflowy_editor
flutter pub get
```

## How to use

Let's create a new AppFlowyEditor object 
```dart
final editorState = EditorState.empty(); // an empty state
final editor = AppFlowyEditor(
    editorState: editorState,
    keyEventHandlers: const [],
    customBuilders: const {},
);
```

You can also create an editor from a JSON file
```dart
final json = ...;
final editorState = EditorState(StateTree.fromJson(data));
final editor = AppFlowyEditor(
    editorState: editorState,
    keyEventHandlers: const [],
    customBuilders: const {},
);
```

To get a sense for how you might use it, run this example:
```shell
git clone https://github.com/AppFlowy-IO/AppFlowy.git
cd frontend/app_flowy/packages/appflowy_editor/example
flutter run
```


## How to customize 
### Customize a component
Please refer to [customizing a component](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/customizing.md#customize-a-component) for more details.


### Customize a shortcut event
Please refer to [customizing a shortcut event](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/customizing.md#customize-a-shortcut-event) for more details.

## More Examples
* Customize a component
    * [Checkbox Text](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/render/rich_text/checkbox_text.dart) shows you how to extend new styles based on existing rich text components
    * [Image](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/example/lib/plugin/network_image_node_widget.dart) teaches you how to extend a new node and render it
    * And more examples on [rich-text plugins](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/render/rich_text)
* Customize a shortcut event
    * [BIUS](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/service/internal_key_event_handlers/update_text_style_by_command_x_handler.dart) shows you how to make text bold/italic/underline/strikethrough through shortcut keys
    * [Paste HTML](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/service/internal_key_event_handlers/copy_paste_handler.dart) gives you an idea on how to handle pasted styles through shortcut keys
    * Need more examples? Check out [Internal key event handlers](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/service/internal_key_event_handlers)

## Glossary
Please refer to the API documentation.

## Contributing
Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are greatly appreciated. Please look at [CONTRIBUTING.md](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/contributing-to-appflowy) for details.

## License
Distributed under the AGPLv3 License. See LICENSE for more information.
