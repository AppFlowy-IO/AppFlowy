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

<p align="center">
    <a href="https://codecov.io/gh/AppFlowy-IO/AppFlowy" >
        <img src="https://codecov.io/gh/AppFlowy-IO/AppFlowy/branch/main/graph/badge.svg?token=YTFKUF70B6"/>
    </a>
</p>

<div align="center">
    <img src="https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/images/appflowy_editor_example.mp4?raw=true" width = "700" style = "padding: 100"/>
</div>

## Key Features

* Build rich, intuitive editors
* Design and modify an ever expanding list of customizable features including
  * components (such as form input controls, numbered lists, and rich text widgets)
  * shortcut events
  * themes
  * menu options (**coming soon!**)
* [Test-coverage](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/testing.md) and on-going maintenance by AppFlowy's core team and community of more than 1,000 builders

## Getting Started

Add the AppFlowy editor [Flutter package](https://docs.flutter.dev/development/packages-and-plugins/using-packages) to your environment.

```shell
flutter pub add appflowy_editor
flutter pub get
```

## Creating Your First Editor

Start by creating a new empty AppFlowyEditor object. 

```dart
final editorStyle = EditorStyle.defaultStyle();
final editorState = EditorState.empty(); // an empty state
final editor = AppFlowyEditor(
    editorState: editorState,
    editorStyle: editorStyle,
);
```

You can also create an editor from a JSON object in order to configure your initial state.

```dart
final json = ...;
final editorStyle = EditorStyle.defaultStyle();
final editorState = EditorState(StateTree.fromJson(data));
final editor = AppFlowyEditor(
    editorState: editorState,
    editorStyle: editorStyle,
);
```

> Note: The parameters `localizationsDelegates` need to be assigned in MaterialApp widget
```dart
MaterialApp(
    localizationsDelegates: const [
        AppFlowyEditorLocalizations.delegate,
    ]，
);
```

To get a sense for how the AppFlowy Editor works, run our example:

```shell
git clone https://github.com/AppFlowy-IO/AppFlowy.git
cd frontend/app_flowy/packages/appflowy_editor/example
flutter run
```

## Customizing Your Editor

### Customizing Components

Please refer to our documentation on customizing AppFlowy for a detailed discussion about [customizing components](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/customizing.md#customize-a-component).

Below are some examples of component customizations:

 * [Checkbox Text](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/render/rich_text/checkbox_text.dart) demonstrates how to extend new styles based on existing rich text components
 * [Image](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/example/lib/plugin/network_image_node_widget.dart) demonstrates how to extend a new node and render it
 * See further examples of [rich-text plugins](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/render/rich_text)
    
### Customizing Shortcut Events

Please refer to our documentation on customizing AppFlowy for a detailed discussion about [customizing shortcut events](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/documentation/customizing.md#customize-a-shortcut-event).

Below are some examples of shortcut event customizations:

 * [BIUS](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/service/internal_key_event_handlers/format_style_handler.dart) demonstrates how to make text bold/italic/underline/strikethrough through shortcut keys
 * [Paste HTML](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/service/internal_key_event_handlers/copy_paste_handler.dart) gives you an idea on how to handle pasted styles through shortcut keys
 * Need more examples? Check out [Internal key event handlers](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/service/internal_key_event_handlers)

## Glossary
Please refer to the API documentation.

## Contributing
Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are greatly appreciated. 

Please look at [CONTRIBUTING.md](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/contributing-to-appflowy) for details.

## License
Distributed under the AGPLv3 License. See [LICENSE](https://github.com/AppFlowy-IO/AppFlowy-Docs/blob/main/LICENSE) for more information.
