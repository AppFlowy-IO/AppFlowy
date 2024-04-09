import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_item_list_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_language_screen.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/all.dart';
import 'package:provider/provider.dart';

import 'code_block_themes.dart';

final supportedLanguages = [
  'Assembly',
  'Bash',
  'BASIC',
  'C',
  'C#',
  'CPP',
  'Clojure',
  'CS',
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

final codeBlockSupportedLanguages = supportedLanguages
    .map((e) => e.toLowerCase())
    .toSet()
    .intersection(allLanguages.keys.toSet())
    .toList()
  ..add('auto')
  ..add('c')
  ..sort();

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
  getName: LocaleKeys.document_selectionMenu_codeBlock.tr,
  iconData: Icons.abc,
  keywords: ['code', 'codeblock'],
  nodeBuilder: (editorState, _) => codeBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

class CodeBlockComponentBuilder extends BlockComponentBuilder {
  CodeBlockComponentBuilder({
    super.configuration,
    this.padding = const EdgeInsets.all(0),
  });

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
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: CodeBlockKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => node.key;

  @override
  Node get node => widget.node;

  final popoverController = PopoverController();

  @override
  late final editorState = context.read<EditorState>();

  String? get language => node.attributes[CodeBlockKeys.language] as String?;
  String? autoDetectLanguage;

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );
    Widget child = Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: AFThemeExtension.of(context).calloutBGColor,
      ),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        textDirection: textDirection,
        children: [
          _buildSwitchLanguageButton(context),
          _buildCodeBlock(context, textDirection),
        ],
      ),
    );

    child = Padding(
      key: blockComponentKey,
      padding: padding,
      child: child,
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (PlatformExtension.isDesktopOrWeb) {
      if (widget.showActions && widget.actionBuilder != null) {
        child = BlockComponentActionWrapper(
          node: widget.node,
          actionBuilder: widget.actionBuilder!,
          child: child,
        );
      }
    } else {
      // show a fixed menu on mobile
      child = MobileBlockActionButtons(
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    return child;
  }

  Widget _buildCodeBlock(BuildContext context, TextDirection textDirection) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
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
    final codeTextSpans = _convert(codeNodes, isLightMode: isLightMode);
    return Padding(
      padding: widget.padding,
      child: AppFlowyRichText(
        key: forwardKey,
        delegate: this,
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
        textDirection: textDirection,
        cursorColor: editorState.editorStyle.cursorColor,
        selectionColor: editorState.editorStyle.selectionColor,
      ),
    );
  }

  Widget _buildSwitchLanguageButton(BuildContext context) {
    const maxWidth = 100.0;

    Widget child = Container(
      width: maxWidth,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(
        top: 4.0,
        left: 4.0,
        bottom: 12.0,
      ),
      child: FlowyTextButton(
        '${language?.capitalize() ?? 'Auto'} ',
        constraints: const BoxConstraints(maxWidth: maxWidth),
        fontColor: Theme.of(context).colorScheme.onBackground,
        fillColor: Colors.transparent,
        onPressed: () async {
          if (PlatformExtension.isMobile) {
            final language = await context.push<String>(
              MobileCodeLanguagePickerScreen.routeName,
            );
            if (language != null) {
              unawaited(updateLanguage(language));
            }
          }
        },
      ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      child = AppFlowyPopover(
        controller: popoverController,
        child: child,
        popupBuilder: (BuildContext context) {
          return SelectableItemListMenu(
            items:
                codeBlockSupportedLanguages.map((e) => e.capitalize()).toList(),
            selectedIndex: codeBlockSupportedLanguages.indexOf(language ?? ''),
            onSelected: (index) {
              updateLanguage(codeBlockSupportedLanguages[index]);
              popoverController.close();
            },
          );
        },
      );
    }

    return child;
  }

  Future<void> updateLanguage(String language) async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        CodeBlockKeys.language: language == 'auto' ? null : language,
      })
      ..afterSelection = Selection.collapsed(
        Position(path: node.path, offset: node.delta?.length ?? 0),
      );
    await editorState.apply(transaction);
  }

  // Copy from flutter.highlight package.
  // https://github.com/git-touch/highlight.dart/blob/master/flutter_highlight/lib/flutter_highlight.dart
  List<TextSpan> _convert(
    List<highlight.Node> nodes, {
    bool isLightMode = true,
  }) {
    final List<TextSpan> spans = [];
    var currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    final codeblockTheme =
        isLightMode ? lightThemeInCodeblock : darkThemeInCodeBlock;

    void traverse(highlight.Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(
                  text: node.value,
                  style: codeblockTheme[node.className!],
                ),
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(
            children: tmp,
            style: codeblockTheme[node.className!],
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
