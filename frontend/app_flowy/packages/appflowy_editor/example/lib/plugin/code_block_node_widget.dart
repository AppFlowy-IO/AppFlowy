import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/all.dart';

ShortcutEvent enterInCodeBlock = ShortcutEvent(
  key: 'Enter in code block',
  command: 'enter',
  handler: _enterInCodeBlockHandler,
);

ShortcutEvent ignoreKeysInCodeBlock = ShortcutEvent(
  key: 'White space in code block',
  command: 'space,slash,shift+underscore',
  handler: _ignorekHandler,
);

ShortcutEventHandler _enterInCodeBlockHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final codeBlockNode =
      nodes.whereType<TextNode>().where((node) => node.id == 'text/code_block');
  if (codeBlockNode.length != 1 || selection == null) {
    return KeyEventResult.ignored;
  }
  if (selection.isCollapsed) {
    TransactionBuilder(editorState)
      ..insertText(codeBlockNode.first, selection.end.offset, '\n')
      ..commit();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _ignorekHandler = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final codeBlockNodes =
      nodes.whereType<TextNode>().where((node) => node.id == 'text/code_block');
  if (codeBlockNodes.length == 1) {
    return KeyEventResult.skipRemainingHandlers;
  }
  return KeyEventResult.ignored;
};

SelectionMenuItem codeBlockItem = SelectionMenuItem(
  name: () => 'Code Block',
  icon: const Icon(Icons.abc),
  keywords: ['code block'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    if (textNodes.first.toRawString().isEmpty) {
      TransactionBuilder(editorState)
        ..updateNode(textNodes.first, {
          'subtype': 'code_block',
          'theme': 'vs',
          'language': null,
        })
        ..afterSelection = selection
        ..commit();
    } else {
      TransactionBuilder(editorState)
        ..insertNode(
          selection.end.path.next,
          TextNode(
            type: 'text',
            children: LinkedList(),
            attributes: {
              'subtype': 'code_block',
              'theme': 'vs',
              'language': null,
            },
            delta: Delta()..insert('\n'),
          ),
        )
        ..afterSelection = selection
        ..commit();
    }
  },
);

class CodeBlockNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return _CodeBlockNodeWidge(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node is TextNode && node.attributes['theme'] is String;
      };
}

class _CodeBlockNodeWidge extends StatefulWidget {
  const _CodeBlockNodeWidge({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;

  @override
  State<_CodeBlockNodeWidge> createState() => __CodeBlockNodeWidgeState();
}

class __CodeBlockNodeWidgeState extends State<_CodeBlockNodeWidge>
    with SelectableMixin, DefaultSelectable {
  final _richTextKey = GlobalKey(debugLabel: 'code_block_text');
  final _padding = const EdgeInsets.only(left: 20, top: 20, bottom: 20);
  String? get _language => widget.textNode.attributes['language'] as String?;
  String? _detectLanguage;

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  GlobalKey<State<StatefulWidget>>? get iconKey => null;

  @override
  Offset get baseOffset => super.baseOffset + _padding.topLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildCodeBlock(context),
        _buildSwitchCodeButton(context),
      ],
    );
  }

  Widget _buildCodeBlock(BuildContext context) {
    final result = highlight.highlight.parse(
      widget.textNode.toRawString(),
      language: _language,
      autoDetection: _language == null,
    );
    _detectLanguage = _language ?? result.language;
    final code = result.nodes;
    final codeTextSpan = _convert(code!);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: Colors.grey.withOpacity(0.1),
      ),
      padding: _padding,
      width: MediaQuery.of(context).size.width,
      child: FlowyRichText(
        key: _richTextKey,
        textNode: widget.textNode,
        editorState: widget.editorState,
        textSpanDecorator: (textSpan) => TextSpan(
          style: widget.editorState.editorStyle.textStyle.defaultTextStyle,
          children: codeTextSpan,
        ),
      ),
    );
  }

  Widget _buildSwitchCodeButton(BuildContext context) {
    return Positioned(
      top: -5,
      right: 0,
      child: DropdownButton<String>(
        value: _detectLanguage,
        onChanged: (value) {
          TransactionBuilder(widget.editorState)
            ..updateNode(widget.textNode, {
              'language': value,
            })
            ..commit();
        },
        items: allLanguages.keys.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.0),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  // Copy from flutter.highlight package.
  // https://github.com/git-touch/highlight.dart/blob/master/flutter_highlight/lib/flutter_highlight.dart
  List<TextSpan> _convert(List<highlight.Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    _traverse(highlight.Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(
                text: node.value,
                style: _builtInCodeBlockTheme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans.add(TextSpan(
            children: tmp, style: _builtInCodeBlockTheme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          _traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      _traverse(node);
    }

    return spans;
  }
}

const _builtInCodeBlockTheme = {
  'root':
      TextStyle(backgroundColor: Color(0xffffffff), color: Color(0xff000000)),
  'comment': TextStyle(color: Color(0xff007400)),
  'quote': TextStyle(color: Color(0xff007400)),
  'tag': TextStyle(color: Color(0xffaa0d91)),
  'attribute': TextStyle(color: Color(0xffaa0d91)),
  'keyword': TextStyle(color: Color(0xffaa0d91)),
  'selector-tag': TextStyle(color: Color(0xffaa0d91)),
  'literal': TextStyle(color: Color(0xffaa0d91)),
  'name': TextStyle(color: Color(0xffaa0d91)),
  'variable': TextStyle(color: Color(0xff3F6E74)),
  'template-variable': TextStyle(color: Color(0xff3F6E74)),
  'code': TextStyle(color: Color(0xffc41a16)),
  'string': TextStyle(color: Color(0xffc41a16)),
  'meta-string': TextStyle(color: Color(0xffc41a16)),
  'regexp': TextStyle(color: Color(0xff0E0EFF)),
  'link': TextStyle(color: Color(0xff0E0EFF)),
  'title': TextStyle(color: Color(0xff1c00cf)),
  'symbol': TextStyle(color: Color(0xff1c00cf)),
  'bullet': TextStyle(color: Color(0xff1c00cf)),
  'number': TextStyle(color: Color(0xff1c00cf)),
  'section': TextStyle(color: Color(0xff643820)),
  'meta': TextStyle(color: Color(0xff643820)),
  'type': TextStyle(color: Color(0xff5c2699)),
  'built_in': TextStyle(color: Color(0xff5c2699)),
  'builtin-name': TextStyle(color: Color(0xff5c2699)),
  'params': TextStyle(color: Color(0xff5c2699)),
  'attr': TextStyle(color: Color(0xff836C28)),
  'subst': TextStyle(color: Color(0xff000000)),
  'formula': TextStyle(
      backgroundColor: Color(0xffeeeeee), fontStyle: FontStyle.italic),
  'addition': TextStyle(backgroundColor: Color(0xffbaeeba)),
  'deletion': TextStyle(backgroundColor: Color(0xffffc8bd)),
  'selector-id': TextStyle(color: Color(0xff9b703f)),
  'selector-class': TextStyle(color: Color(0xff9b703f)),
  'doctag': TextStyle(fontWeight: FontWeight.bold),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
};
