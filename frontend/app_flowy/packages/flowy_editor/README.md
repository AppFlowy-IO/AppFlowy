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

一个可扩展，测试覆盖的 flutter 富文本编辑组件

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

* 可扩展的
    * 支持扩展不同样式的视图
    * 支持定制快捷键解析
    * 支持扩展toolbar/popup list样式(WIP)
    * ...
* 协同结构 ready
    * 
* 质量保证的
    * 由于可扩展的结构，以及随着功能的增多，我们鼓励每个提交的文件或者代码段，都可以在test下增加对应的测试用例代码，尽可能得保证提交者不需要担心自己的代码影响了已有的逻辑。


## Getting started

```shell
flutter pub add flowy_editor
flutter pub get
```

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

Empty document
```dart
final editorState = EditorState.empty();
final editor = FlowyEditor(
    editorState: editorState,
    keyEventHandlers: const [],
    customBuilders: const {},
);
```

从JSON文件中读取
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

## Examples

## Documentation
* 术语表

## Additional information
TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.

目前正在完善更多的文档信息
* Selection
* 

我们还有很多工作需要继续完成，
Project checker link.
