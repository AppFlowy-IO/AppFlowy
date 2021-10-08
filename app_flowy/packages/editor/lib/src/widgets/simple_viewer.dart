import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:string_validator/string_validator.dart';
import 'package:tuple/tuple.dart';

import '../models/documents/attribute.dart';
import '../models/documents/document.dart';
import '../models/documents/nodes/block.dart';
import '../models/documents/nodes/leaf.dart' as leaf;
import '../models/documents/nodes/line.dart';
import 'controller.dart';
import 'cursor.dart';
import 'default_styles.dart';
import 'delegate.dart';
import 'editor.dart';
import 'text_block.dart';
import 'text_line.dart';
import 'video_app.dart';
import 'youtube_video_app.dart';

class QuillSimpleViewer extends StatefulWidget {
  const QuillSimpleViewer({
    required this.controller,
    required this.readOnly,
    this.customStyles,
    this.truncate = false,
    this.truncateScale,
    this.truncateAlignment,
    this.truncateHeight,
    this.truncateWidth,
    this.scrollBottomInset = 0,
    this.padding = EdgeInsets.zero,
    this.embedBuilder,
    Key? key,
  })  : assert(truncate ||
            ((truncateScale == null) &&
                (truncateAlignment == null) &&
                (truncateHeight == null) &&
                (truncateWidth == null))),
        super(key: key);

  final QuillController controller;
  final DefaultStyles? customStyles;
  final bool truncate;
  final double? truncateScale;
  final Alignment? truncateAlignment;
  final double? truncateHeight;
  final double? truncateWidth;
  final double scrollBottomInset;
  final EdgeInsetsGeometry padding;
  final EmbedBuilder? embedBuilder;
  final bool readOnly;

  @override
  _QuillSimpleViewerState createState() => _QuillSimpleViewerState();
}

class _QuillSimpleViewerState extends State<QuillSimpleViewer>
    with SingleTickerProviderStateMixin {
  late DefaultStyles _styles;
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  late CursorCont _cursorCont;

  @override
  void initState() {
    super.initState();

    _cursorCont = CursorCont(
      show: ValueNotifier<bool>(false),
      style: const CursorStyle(
        color: Colors.black,
        backgroundColor: Colors.grey,
        width: 2,
        radius: Radius.zero,
        offset: Offset.zero,
      ),
      tickerProvider: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentStyles = QuillStyles.getStyles(context, true);
    final defaultStyles = DefaultStyles.getInstance(context);
    _styles = (parentStyles != null)
        ? defaultStyles.merge(parentStyles)
        : defaultStyles;

    if (widget.customStyles != null) {
      _styles = _styles.merge(widget.customStyles!);
    }
  }

  EmbedBuilder get embedBuilder => widget.embedBuilder ?? _defaultEmbedBuilder;

  Widget _defaultEmbedBuilder(
      BuildContext context, leaf.Embed node, bool readOnly) {
    assert(!kIsWeb, 'Please provide EmbedBuilder for Web');
    switch (node.value.type) {
      case 'image':
        final imageUrl = _standardizeImageUrl(node.value.data);
        return imageUrl.startsWith('http')
            ? Image.network(imageUrl)
            : isBase64(imageUrl)
                ? Image.memory(base64.decode(imageUrl))
                : Image.file(io.File(imageUrl));
      case 'video':
        final videoUrl = node.value.data;
        if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
          return YoutubeVideoApp(
              videoUrl: videoUrl, context: context, readOnly: readOnly);
        }
        return VideoApp(
            videoUrl: videoUrl, context: context, readOnly: readOnly);
      default:
        throw UnimplementedError(
          'Embeddable type "${node.value.type}" is not supported by default '
          'embed builder of QuillEditor. You must pass your own builder '
          'function to embedBuilder property of QuillEditor or QuillField '
          'widgets.',
        );
    }
  }

  String _standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final _doc = widget.controller.document;
    // if (_doc.isEmpty() &&
    //     !widget.focusNode.hasFocus &&
    //     widget.placeholder != null) {
    //   _doc = Document.fromJson(jsonDecode(
    //       '[{"attributes":{"placeholder":true},"insert":"${widget.placeholder}\\n"}]'));
    // }

    Widget child = CompositedTransformTarget(
      link: _toolbarLayerLink,
      child: Semantics(
        child: _SimpleViewer(
          document: _doc,
          textDirection: _textDirection,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          onSelectionChanged: _nullSelectionChanged,
          scrollBottomInset: widget.scrollBottomInset,
          padding: widget.padding,
          children: _buildChildren(_doc, context),
        ),
      ),
    );

    if (widget.truncate) {
      if (widget.truncateScale != null) {
        child = Container(
            height: widget.truncateHeight,
            child: Align(
                heightFactor: widget.truncateScale,
                widthFactor: widget.truncateScale,
                alignment: widget.truncateAlignment ?? Alignment.topLeft,
                child: Container(
                    width: widget.truncateWidth! / widget.truncateScale!,
                    child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Transform.scale(
                            scale: widget.truncateScale!,
                            alignment:
                                widget.truncateAlignment ?? Alignment.topLeft,
                            child: child)))));
      } else {
        child = Container(
            height: widget.truncateHeight,
            width: widget.truncateWidth,
            child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), child: child));
      }
    }

    return QuillStyles(data: _styles, child: child);
  }

  List<Widget> _buildChildren(Document doc, BuildContext context) {
    final result = <Widget>[];
    final indentLevelCounts = <int, int>{};
    for (final node in doc.root.children) {
      if (node is Line) {
        final editableTextLine = _getEditableTextLineFromNode(node, context);
        result.add(editableTextLine);
      } else if (node is Block) {
        final attrs = node.style.attributes;
        final editableTextBlock = EditableTextBlock(
            block: node,
            textDirection: _textDirection,
            scrollBottomInset: widget.scrollBottomInset,
            verticalSpacing: _getVerticalSpacingForBlock(node, _styles),
            textSelection: widget.controller.selection,
            color: Colors.black,
            styles: _styles,
            enableInteractiveSelection: false,
            hasFocus: false,
            contentPadding: attrs.containsKey(Attribute.codeBlock.key)
                ? const EdgeInsets.all(16)
                : null,
            embedBuilder: embedBuilder,
            cursorCont: _cursorCont,
            indentLevelCounts: indentLevelCounts,
            onCheckboxTap: _handleCheckboxTap,
            readOnly: widget.readOnly);
        result.add(editableTextBlock);
      } else {
        throw StateError('Unreachable.');
      }
    }
    return result;
  }

  /// Updates the checkbox positioned at [offset] in document
  /// by changing its attribute according to [value].
  void _handleCheckboxTap(int offset, bool value) {
    // readonly - do nothing
  }

  TextDirection get _textDirection {
    final result = Directionality.of(context);
    return result;
  }

  EditableTextLine _getEditableTextLineFromNode(
      Line node, BuildContext context) {
    final textLine = TextLine(
      line: node,
      textDirection: _textDirection,
      embedBuilder: embedBuilder,
      styles: _styles,
      readOnly: widget.readOnly,
    );
    final editableTextLine = EditableTextLine(
        node,
        null,
        textLine,
        0,
        _getVerticalSpacingForLine(node, _styles),
        _textDirection,
        widget.controller.selection,
        Colors.black,
        //widget.selectionColor,
        false,
        //enableInteractiveSelection,
        false,
        //_hasFocus,
        MediaQuery.of(context).devicePixelRatio,
        _cursorCont);
    return editableTextLine;
  }

  Tuple2<double, double> _getVerticalSpacingForLine(
      Line line, DefaultStyles? defaultStyles) {
    final attrs = line.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final int? level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          return defaultStyles!.h1!.verticalSpacing;
        case 2:
          return defaultStyles!.h2!.verticalSpacing;
        case 3:
          return defaultStyles!.h3!.verticalSpacing;
        default:
          throw 'Invalid level $level';
      }
    }

    return defaultStyles!.paragraph!.verticalSpacing;
  }

  Tuple2<double, double> _getVerticalSpacingForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.indent.key)) {
      return defaultStyles!.indent!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.list.key)) {
      return defaultStyles!.lists!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.align.key)) {
      return defaultStyles!.align!.verticalSpacing;
    }
    return const Tuple2(0, 0);
  }

  void _nullSelectionChanged(
      TextSelection selection, SelectionChangedCause cause) {}
}

class _SimpleViewer extends MultiChildRenderObjectWidget {
  _SimpleViewer({
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.onSelectionChanged,
    required this.scrollBottomInset,
    this.padding = EdgeInsets.zero,
    Key? key,
  }) : super(key: key, children: children);

  final Document document;
  final TextDirection textDirection;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final TextSelectionChangedHandler onSelectionChanged;
  final double scrollBottomInset;
  final EdgeInsetsGeometry padding;

  @override
  RenderEditor createRenderObject(BuildContext context) {
    return RenderEditor(
      null,
      textDirection,
      scrollBottomInset,
      padding,
      document,
      const TextSelection(baseOffset: 0, extentOffset: 0),
      false,
      // hasFocus,
      onSelectionChanged,
      startHandleLayerLink,
      endHandleLayerLink,
      const EdgeInsets.fromLTRB(4, 4, 4, 5),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditor renderObject) {
    renderObject
      ..document = document
      ..setContainer(document.root)
      ..textDirection = textDirection
      ..setStartHandleLayerLink(startHandleLayerLink)
      ..setEndHandleLayerLink(endHandleLayerLink)
      ..onSelectionChanged = onSelectionChanged
      ..setScrollBottomInset(scrollBottomInset)
      ..setPadding(padding);
  }
}
