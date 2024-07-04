import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/markdown_code_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import 'selectable_highlight.dart';

enum AIMarkdownType {
  appflowyEditor,
  markdownWidget,
}

// Wrap the appflowy_editor or markdown_widget as a chat text message widget
class AIMarkdownText extends StatelessWidget {
  const AIMarkdownText({
    super.key,
    required this.markdown,
    this.type = AIMarkdownType.appflowyEditor,
  });

  final String markdown;
  final AIMarkdownType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AIMarkdownType.appflowyEditor:
        return _AppFlowyEditorMarkdown(markdown: markdown);
      case AIMarkdownType.markdownWidget:
        return _ThirdPartyMarkdown(markdown: markdown);
    }
  }
}

class _AppFlowyEditorMarkdown extends StatefulWidget {
  const _AppFlowyEditorMarkdown({
    required this.markdown,
  });

  // the text should be the markdown format
  final String markdown;

  @override
  State<_AppFlowyEditorMarkdown> createState() =>
      _AppFlowyEditorMarkdownState();
}

class _AppFlowyEditorMarkdownState extends State<_AppFlowyEditorMarkdown> {
  late EditorState editorState;
  late final styleCustomizer = EditorStyleCustomizer(
    context: context,
    padding: EdgeInsets.zero,
  );
  late final editorStyle = styleCustomizer.style().copyWith(
        // hide the cursor
        cursorColor: Colors.transparent,
        cursorWidth: 0,
      );

  @override
  void initState() {
    super.initState();

    editorState = _parseMarkdown(widget.markdown);
  }

  @override
  void didUpdateWidget(covariant _AppFlowyEditorMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.markdown != widget.markdown) {
      editorState.dispose();
      editorState = _parseMarkdown(widget.markdown);
    }
  }

  @override
  void dispose() {
    editorState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockBuilders = getEditorBuilderMap(
      context: context,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      // the editor is not editable in the chat
      editable: false,
    );
    return IntrinsicHeight(
      child: AppFlowyEditor(
        shrinkWrap: true,
        // the editor is not editable in the chat
        editable: false,
        editorStyle: editorStyle,
        blockComponentBuilders: blockBuilders,
        editorState: editorState,
      ),
    );
  }

  EditorState _parseMarkdown(String markdown) {
    final document = markdownToDocument(
      markdown,
      markdownParsers: [
        const MarkdownCodeBlockParser(),
      ],
    );
    final editorState = EditorState(document: document);
    return editorState;
  }
}

class _ThirdPartyMarkdown extends StatelessWidget {
  const _ThirdPartyMarkdown({
    required this.markdown,
  });

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return MarkdownWidget(
      data: markdown,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      config: configFromContext(context),
    );
  }

  MarkdownConfig configFromContext(BuildContext context) {
    return MarkdownConfig(
      configs: [
        HrConfig(color: AFThemeExtension.of(context).textColor),
        _ChatH1Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          dividerColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        _ChatH2Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          dividerColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        _ChatH3Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          dividerColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        H4Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        H5Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        H6Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        PreConfig(
          builder: (code, language) {
            return ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 800,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                child: SelectableHighlightView(
                  code,
                  language: language,
                  theme: getHighlightTheme(context),
                  padding: const EdgeInsets.all(14),
                  textStyle: TextStyle(
                    color: AFThemeExtension.of(context).textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        PConfig(
          textStyle: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        CodeConfig(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        BlockquoteConfig(
          sideColor: AFThemeExtension.of(context).lightGreyHover,
          textColor: AFThemeExtension.of(context).textColor,
        ),
      ],
    );
  }

  Map<String, TextStyle> getHighlightTheme(BuildContext context) {
    return {
      'root': TextStyle(
        color: const Color(0xffabb2bf),
        backgroundColor:
            Theme.of(context).isLightMode ? Colors.white : Colors.black38,
      ),
      'comment': const TextStyle(
        color: Color(0xff5c6370),
        fontStyle: FontStyle.italic,
      ),
      'quote': const TextStyle(
        color: Color(0xff5c6370),
        fontStyle: FontStyle.italic,
      ),
      'doctag': const TextStyle(color: Color(0xffc678dd)),
      'keyword': const TextStyle(color: Color(0xffc678dd)),
      'formula': const TextStyle(color: Color(0xffc678dd)),
      'section': const TextStyle(color: Color(0xffe06c75)),
      'name': const TextStyle(color: Color(0xffe06c75)),
      'selector-tag': const TextStyle(color: Color(0xffe06c75)),
      'deletion': const TextStyle(color: Color(0xffe06c75)),
      'subst': const TextStyle(color: Color(0xffe06c75)),
      'literal': const TextStyle(color: Color(0xff56b6c2)),
      'string': const TextStyle(color: Color(0xff98c379)),
      'regexp': const TextStyle(color: Color(0xff98c379)),
      'addition': const TextStyle(color: Color(0xff98c379)),
      'attribute': const TextStyle(color: Color(0xff98c379)),
      'meta-string': const TextStyle(color: Color(0xff98c379)),
      'built_in': const TextStyle(color: Color(0xffe6c07b)),
      'attr': const TextStyle(color: Color(0xffd19a66)),
      'variable': const TextStyle(color: Color(0xffd19a66)),
      'template-variable': const TextStyle(color: Color(0xffd19a66)),
      'type': const TextStyle(color: Color(0xffd19a66)),
      'selector-class': const TextStyle(color: Color(0xffd19a66)),
      'selector-attr': const TextStyle(color: Color(0xffd19a66)),
      'selector-pseudo': const TextStyle(color: Color(0xffd19a66)),
      'number': const TextStyle(color: Color(0xffd19a66)),
      'symbol': const TextStyle(color: Color(0xff61aeee)),
      'bullet': const TextStyle(color: Color(0xff61aeee)),
      'link': const TextStyle(color: Color(0xff61aeee)),
      'meta': const TextStyle(color: Color(0xff61aeee)),
      'selector-id': const TextStyle(color: Color(0xff61aeee)),
      'title': const TextStyle(color: Color(0xff61aeee)),
      'emphasis': const TextStyle(fontStyle: FontStyle.italic),
      'strong': const TextStyle(fontWeight: FontWeight.bold),
    };
  }
}

class _ChatH1Config extends HeadingConfig {
  const _ChatH1Config({
    this.style = const TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.bold,
    ),
    required this.dividerColor,
  });

  @override
  final TextStyle style;
  final Color dividerColor;

  @override
  String get tag => MarkdownTag.h1.name;

  @override
  HeadingDivider? get divider => HeadingDivider(
        space: 10,
        color: dividerColor,
        height: 10,
      );
}

///config class for h2
class _ChatH2Config extends HeadingConfig {
  const _ChatH2Config({
    this.style = const TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.bold,
    ),
    required this.dividerColor,
  });
  @override
  final TextStyle style;
  final Color dividerColor;

  @override
  String get tag => MarkdownTag.h2.name;

  @override
  HeadingDivider? get divider => HeadingDivider(
        space: 10,
        color: dividerColor,
        height: 10,
      );
}

class _ChatH3Config extends HeadingConfig {
  const _ChatH3Config({
    this.style = const TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.bold,
    ),
    required this.dividerColor,
  });

  @override
  final TextStyle style;
  final Color dividerColor;

  @override
  String get tag => MarkdownTag.h3.name;

  @override
  HeadingDivider? get divider => HeadingDivider(
        space: 10,
        color: dividerColor,
        height: 10,
      );
}
