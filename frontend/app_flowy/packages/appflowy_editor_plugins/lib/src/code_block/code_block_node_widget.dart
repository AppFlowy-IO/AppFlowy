import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/all.dart';

const String kCodeBlockType = 'text/$kCodeBlockSubType';
const String kCodeBlockSubType = 'code_block';
const String kCodeBlockAttrTheme = 'theme';
const String kCodeBlockAttrLanguage = 'language';

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
        return node is TextNode &&
            node.attributes[kCodeBlockAttrTheme] is String;
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
  final _richTextKey = GlobalKey(debugLabel: kCodeBlockType);
  final _padding = const EdgeInsets.only(left: 20, top: 30, bottom: 30);
  bool _isHover = false;
  String? get _language =>
      widget.textNode.attributes[kCodeBlockAttrLanguage] as String?;
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
    return InkWell(
      onHover: (value) {
        setState(() {
          _isHover = value;
        });
      },
      onTap: () {},
      child: Stack(
        children: [
          _buildCodeBlock(context),
          _buildSwitchCodeButton(context),
          if (_isHover) _buildDeleteButton(context),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context) {
    final result = highlight.highlight.parse(
      widget.textNode.toPlainText(),
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
          style: widget.editorState.editorStyle.textStyle,
          children: codeTextSpan,
        ),
      ),
    );
  }

  Widget _buildSwitchCodeButton(BuildContext context) {
    return Positioned(
      top: -5,
      left: 10,
      child: SizedBox(
        height: 35,
        child: DropdownButton<String>(
          value: _detectLanguage,
          iconSize: 14.0,
          onChanged: (value) {
            final transaction = widget.editorState.transaction
              ..updateNode(widget.textNode, {
                kCodeBlockAttrLanguage: value,
              });
            widget.editorState.apply(transaction);
          },
          items:
              allLanguages.keys.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 12.0),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Positioned(
      top: -5,
      right: -5,
      child: IconButton(
        icon: Icon(
          Icons.delete_forever_outlined,
          color: widget.editorState.editorStyle.selectionMenuItemIconColor,
          size: 16,
        ),
        onPressed: () {
          final transaction = widget.editorState.transaction
            ..deleteNode(widget.textNode);
          widget.editorState.apply(transaction);
        },
      ),
    );
  }

  // Copy from flutter.highlight package.
  // https://github.com/git-touch/highlight.dart/blob/master/flutter_highlight/lib/flutter_highlight.dart
  List<TextSpan> _convert(List<highlight.Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    void traverse(highlight.Node node) {
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
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
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
