# Testing

目前测试文件的目录结构与代码文件的目录结构是保持一致的，这样方便我们查找新增文件的测试情况，以及方便检索对应文件的测试代码路径。

## 提供的测试方法


构造测试的文档数据
```dart
const text = 'Welcome to Appflowy 😁';
// 获取编辑器
final editor = tester.editor;
// 插入空的文本节点
editor.insertEmptyTextNode();
// 插入带信息的文本节点
editor.insertTextNode(text);
// 插入样式heading的文本节点
editor.insertTextNode(text, attributes: {
    StyleKey.subtype: StyleKey.heading,
    StyleKey.heading: StyleKey.h1,
});
// 插入样式bulleted list的加粗的文本节点
editor.insertTextNode(
    '',
    attributes: {
        StyleKey.subtype: StyleKey.bulletedList,
    },
    delta: Delta([
        TextInsert(text, {StyleKey.bold: true}),
    ]),
);
```

在测试前必须调用
```dart
await editor.startTesting();
```

获取当前渲染的节点数量
```dart
final length = editor.documentLength;
print(length);
```

获取节点
```dart
// 获取上述文档结构中的第一个文本节点
final firstTextNode = editor.nodeAtPath([0]) as TextNode;
```

更新选区信息
```dart
await editor.updateSelection(
    Selection.single(path: firstTextNode.path, startOffset: 0),
);
```

获取选区信息
```dart
final selection = editor.documentSelection;
print(selection);
```

模拟快捷键输入
```dart
// 输入 command + A
await editor.pressLogicKey(LogicalKeyboardKey.keyA, isMetaPressed: true);
// 输入 command + shift + S
await editor.pressLogicKey(
    LogicalKeyboardKey.keyS, 
    isMetaPressed: true, 
    isShiftPressed: true,
);
```

模拟文字输入
```dart
// 在第一个节点的最起始位置插入'Hello World'
editor.insertText(firstTextNode, 'Hello World', 0);
```

获取文本节点的信息
```dart
// 获取纯文字
final textAfterInserted = firstTextNode.toRawString();
print(textAfterInserted);
// 获取文字的描述信息
final attributes = firstTextNode.attributes;
print(attributes);
```

## Example
例如，目前需要测试 select_all_handler.dart 的文件

完整的例子
```dart
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('select_all_handler_test.dart', () {
    testWidgets('Presses Command + A in the document', (tester) async {
        const lines = 100;
        const text = 'Welcome to Appflowy 😁';
        final editor = tester.editor;
        for (var i = 0; i < lines; i++) {
            editor.insertTextNode(text);
        }
        await editor.startTesting();
        await editor.pressLogicKey(LogicalKeyboardKey.keyA, isMetaPressed: true);

        expect(
            editor.documentSelection,
            Selection(
            start: Position(path: [0], offset: 0),
            end: Position(path: [lines - 1], offset: text.length),
            ),
        );
    });
}
```

其余关于测试的，例如模拟点击等信息请参考 [An introduction to widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction) 
