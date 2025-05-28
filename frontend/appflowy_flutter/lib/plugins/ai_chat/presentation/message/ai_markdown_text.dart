import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import '../chat_editor_style.dart';

// Wrap the appflowy_editor as a chat text message widget
class AIMarkdownText extends StatelessWidget {
  const AIMarkdownText({
    super.key,
    required this.markdown,
    this.withAnimation = false,
  });

  final String markdown;
  final bool withAnimation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentPageStyleBloc(view: ViewPB())
        ..add(const DocumentPageStyleEvent.initial()),
      child: _AppFlowyEditorMarkdown(
        markdown: markdown,
        withAnimation: withAnimation,
      ),
    );
  }
}

class _AppFlowyEditorMarkdown extends StatefulWidget {
  const _AppFlowyEditorMarkdown({
    required this.markdown,
    this.withAnimation = false,
  });

  // the text should be the markdown format
  final String markdown;

  /// Whether to animate the text.
  final bool withAnimation;

  @override
  State<_AppFlowyEditorMarkdown> createState() =>
      _AppFlowyEditorMarkdownState();
}

class _AppFlowyEditorMarkdownState extends State<_AppFlowyEditorMarkdown>
    with TickerProviderStateMixin {
  late EditorState editorState;
  late EditorScrollController scrollController;
  late Timer markdownOutputTimer;
  int offset = 0;

  final Map<String, (AnimationController, Animation<double>)> _animations = {};

  @override
  void initState() {
    super.initState();

    editorState = _parseMarkdown(widget.markdown.trim());
    scrollController = EditorScrollController(
      editorState: editorState,
      shrinkWrap: true,
    );

    if (widget.withAnimation) {
      markdownOutputTimer =
          Timer.periodic(const Duration(milliseconds: 60), (timer) {
        if (offset >= widget.markdown.length || !widget.withAnimation) {
          return;
        }

        final markdown = widget.markdown.substring(0, offset);
        offset += 30;

        final editorState = _parseMarkdown(
          markdown,
          previousDocument: this.editorState.document,
        );
        final lastCurrentNode = editorState.document.last;
        final lastPreviousNode = this.editorState.document.last;
        if (lastCurrentNode?.id != lastPreviousNode?.id ||
            lastCurrentNode?.type != lastPreviousNode?.type ||
            lastCurrentNode?.delta?.toPlainText() !=
                lastPreviousNode?.delta?.toPlainText()) {
          setState(() {
            this.editorState.dispose();
            this.editorState = editorState;
            scrollController.dispose();
            scrollController = EditorScrollController(
              editorState: editorState,
              shrinkWrap: true,
            );
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AppFlowyEditorMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.markdown != widget.markdown && !widget.withAnimation) {
      final editorState = _parseMarkdown(
        widget.markdown.trim(),
        previousDocument: this.editorState.document,
      );
      this.editorState.dispose();
      this.editorState = editorState;
      scrollController.dispose();
      scrollController = EditorScrollController(
        editorState: editorState,
        shrinkWrap: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    editorState.dispose();

    if (widget.withAnimation) {
      markdownOutputTimer.cancel();
      for (final controller in _animations.values.map((e) => e.$1)) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // don't lazy load the styleCustomizer and blockBuilders,
    // it needs the context to get the theme.
    final styleCustomizer = ChatEditorStyleCustomizer(
      context: context,
      padding: EdgeInsets.zero,
    );
    final editorStyle = styleCustomizer.style().copyWith(
          // hide the cursor
          cursorColor: Colors.transparent,
          cursorWidth: 0,
        );
    final blockBuilders = buildBlockComponentBuilders(
      context: context,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      // the editor is not editable in the chat
      editable: false,
      alwaysDistributeSimpleTableColumnWidths: UniversalPlatform.isDesktop,
      customPadding: (node) => EdgeInsets.zero,
    );
    return IntrinsicHeight(
      child: AppFlowyEditor(
        shrinkWrap: true,
        // the editor is not editable in the chat
        editable: false,
        disableKeyboardService: UniversalPlatform.isMobile,
        disableSelectionService: UniversalPlatform.isMobile,
        editorStyle: editorStyle,
        editorScrollController: scrollController,
        blockComponentBuilders: blockBuilders,
        commandShortcutEvents: [customCopyCommand],
        disableAutoScroll: true,
        editorState: editorState,
        blockWrapper: (
          context, {
          required Node node,
          required Widget child,
        }) {
          if (!widget.withAnimation) {
            return child;
          }

          if (!_animations.containsKey(node.id)) {
            final duration = UniversalPlatform.isMobile
                ? const Duration(milliseconds: 800)
                : const Duration(milliseconds: 1600);
            final controller = AnimationController(
              vsync: this,
              duration: duration,
            );
            final fade = Tween<double>(
              begin: 0,
              end: 1,
            ).animate(controller);
            _animations[node.id] = (controller, fade);
            controller.forward();
          }
          final (controller, fade) = _animations[node.id]!;
          return _AnimatedWrapper(
            fade: fade,
            child: child,
          );
        },
        contextMenuItems: [
          [
            ContextMenuItem(
              getName: LocaleKeys.document_plugins_contextMenu_copy.tr,
              onPressed: (editorState) =>
                  customCopyCommand.execute(editorState),
            ),
          ]
        ],
      ),
    );
  }

  EditorState _parseMarkdown(
    String markdown, {
    Document? previousDocument,
  }) {
    // merge the nodes from the previous document with the new document to keep the same node ids
    final document = customMarkdownToDocument(markdown);
    final documentIterator = NodeIterator(
      document: document,
      startNode: document.root,
    );
    if (previousDocument != null) {
      final previousDocumentIterator = NodeIterator(
        document: previousDocument,
        startNode: previousDocument.root,
      );
      while (
          documentIterator.moveNext() && previousDocumentIterator.moveNext()) {
        final currentNode = documentIterator.current;
        final previousNode = previousDocumentIterator.current;
        if (currentNode.path.equals(previousNode.path)) {
          currentNode.id = previousNode.id;
        }
      }
    }
    final editorState = EditorState(document: document);
    return editorState;
  }
}

class _AnimatedWrapper extends StatelessWidget {
  const _AnimatedWrapper({
    required this.fade,
    required this.child,
  });

  final Animation<double> fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fade,
      builder: (context, childWidget) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              stops: [fade.value, fade.value],
              colors: const [
                Colors.white,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Opacity(
            opacity: fade.value,
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
