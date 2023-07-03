import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_item_list_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/all.dart';
import 'package:provider/provider.dart';

class CodeBlockKeys {
  const CodeBlockKeys._();

  static const String type = 'code';

  /// The content of a code block.
  ///
  /// The value is a String.
  static const String delta = 'delta';

  /// The language of a code block.
  ///
  /// The value is a String.
  static const String language = 'language';
}

Node codeBlockNode({
  Delta? delta,
  String? language,
}) {
  final attributes = {
    CodeBlockKeys.delta: (delta ?? Delta()).toJson(),
    CodeBlockKeys.language: language,
  };
  return Node(
    type: CodeBlockKeys.type,
    attributes: attributes,
  );
}

// defining the callout block menu item for selection
SelectionMenuItem codeBlockItem = SelectionMenuItem.node(
  name: 'Code Block',
  iconData: Icons.abc,
  keywords: ['code', 'codeblock'],
  nodeBuilder: (editorState) => codeBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

class CodeBlockComponentBuilder extends BlockComponentBuilder {
  CodeBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  final BlockComponentConfiguration configuration;

  final EdgeInsets padding;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CodeBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      padding: padding,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.delta != null;
}

class CodeBlockComponentWidget extends BlockComponentStatefulWidget {
  const CodeBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.padding = const EdgeInsets.all(0),
  });

  final EdgeInsets padding;

  @override
  State<CodeBlockComponentWidget> createState() =>
      _CodeBlockComponentWidgetState();
}

class _CodeBlockComponentWidgetState extends State<CodeBlockComponentWidget>
    with SelectableMixin, DefaultSelectable, BlockComponentConfigurable {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => node.key;

  @override
  Node get node => widget.node;

  final popoverController = PopoverController();

  final supportedLanguages = [
    'Assembly',
    'Bash',
    'BASIC',
    'C',
    'C#',
    'C++',
    'Clojure',
    'CSS',
    'Dart',
    'Docker',
    'Elixir',
    'Elm',
    'Erlang',
    'Fortran',
    'Go',
    'GraphQL',
    'Haskell',
    'HTML',
    'Java',
    'JavaScript',
    'JSON',
    'Kotlin',
    'LaTeX',
    'Lisp',
    'Lua',
    'Markdown',
    'MATLAB',
    'Objective-C',
    'OCaml',
    'Perl',
    'PHP',
    'PowerShell',
    'Python',
    'R',
    'Ruby',
    'Rust',
    'Scala',
    'Shell',
    'SQL',
    'Swift',
    'TypeScript',
    'Visual Basic',
    'XML',
    'YAML',
  ];
  late final languages = supportedLanguages
      .map((e) => e.toLowerCase())
      .toSet()
      .intersection(allLanguages.keys.toSet())
      .toList();

  late final editorState = context.read<EditorState>();

  String? get language => node.attributes[CodeBlockKeys.language] as String?;
  String? autoDetectLanguage;

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: Colors.grey.withOpacity(0.1),
      ),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchLanguageButton(context),
          _buildCodeBlock(context),
        ],
      ),
    );

    if (widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: widget.node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }

  Widget _buildCodeBlock(BuildContext context) {
    final delta = node.delta ?? Delta();
    final content = delta.toPlainText();

    final result = highlight.highlight.parse(
      content,
      language: language,
      autoDetection: language == null,
    );
    autoDetectLanguage = language ?? result.language;

    final codeNodes = result.nodes;
    if (codeNodes == null) {
      throw Exception('Code block parse error.');
    }
    final codeTextSpans = _convert(codeNodes);
    return Padding(
      padding: widget.padding,
      child: FlowyRichText(
        key: forwardKey,
        node: widget.node,
        editorState: editorState,
        placeholderText: placeholderText,
        lineHeight: 1.5,
        textSpanDecorator: (textSpan) => TextSpan(
          style: textStyle,
          children: codeTextSpans,
        ),
        placeholderTextSpanDecorator: (textSpan) => TextSpan(
          style: textStyle,
        ),
      ),
    );
  }

  Widget _buildSwitchLanguageButton(BuildContext context) {
    const maxWidth = 100.0;
    return AppFlowyPopover(
      controller: popoverController,
      child: Container(
        width: maxWidth,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FlowyTextButton(
          '${language?.capitalize() ?? 'auto'} ',
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          constraints: const BoxConstraints(maxWidth: maxWidth),
          fontColor: Theme.of(context).colorScheme.onBackground,
          fillColor: Colors.transparent,
          mainAxisAlignment: MainAxisAlignment.start,
          onPressed: () {},
        ),
      ),
      popupBuilder: (BuildContext context) {
        return SelectableItemListMenu(
          items: languages.map((e) => e.capitalize()).toList(),
          selectedIndex: languages.indexOf(language ?? ''),
          onSelected: (index) {
            updateLanguage(languages[index]);
            popoverController.close();
          },
        );
      },
    );
  }

  Future<void> updateLanguage(String language) async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        CodeBlockKeys.language: language,
      })
      ..afterSelection = Selection.collapse(
        node.path,
        node.delta?.length ?? 0,
      );
    await editorState.apply(transaction);
  }

  // Copy from flutter.highlight package.
  // https://github.com/git-touch/highlight.dart/blob/master/flutter_highlight/lib/flutter_highlight.dart
  List<TextSpan> _convert(List<highlight.Node> nodes) {
    final List<TextSpan> spans = [];
    var currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    void traverse(highlight.Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(
                  text: node.value,
                  style: _builtInCodeBlockTheme[node.className!],
                ),
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(
            children: tmp,
            style: _builtInCodeBlockTheme[node.className!],
          ),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (final node in nodes) {
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
    backgroundColor: Color(0xffeeeeee),
    fontStyle: FontStyle.italic,
  ),
  'addition': TextStyle(backgroundColor: Color(0xffbaeeba)),
  'deletion': TextStyle(backgroundColor: Color(0xffffc8bd)),
  'selector-id': TextStyle(color: Color(0xff9b703f)),
  'selector-class': TextStyle(color: Color(0xff9b703f)),
  'doctag': TextStyle(fontWeight: FontWeight.bold),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
};
