import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:tuple/tuple.dart';

import '../models/documents/attribute.dart';
import '../models/documents/document.dart';
import '../models/documents/nodes/block.dart';
import '../models/documents/nodes/line.dart';
import 'controller.dart';
import 'cursor.dart';
import 'default_styles.dart';
import 'delegate.dart';
import 'editor.dart';
import 'keyboard_listener.dart';
import 'proxy.dart';
import 'raw_editor/raw_editor_state_keyboard_mixin.dart';
import 'raw_editor/raw_editor_state_selection_delegate_mixin.dart';
import 'raw_editor/raw_editor_state_text_input_client_mixin.dart';
import 'text_block.dart';
import 'text_line.dart';
import 'text_selection.dart';

class RawEditor extends StatefulWidget {
  const RawEditor(
    Key key,
    this.controller,
    this.focusNode,
    this.scrollController,
    this.scrollable,
    this.scrollBottomInset,
    this.padding,
    this.readOnly,
    this.placeholder,
    this.onLaunchUrl,
    this.toolbarOptions,
    this.showSelectionHandles,
    bool? showCursor,
    this.cursorStyle,
    this.textCapitalization,
    this.maxHeight,
    this.minHeight,
    this.customStyles,
    this.expands,
    this.autoFocus,
    this.selectionColor,
    this.selectionCtrls,
    this.keyboardAppearance,
    this.enableInteractiveSelection,
    this.scrollPhysics,
    this.embedBuilder,
    this.customStyleBuilder,
  )   : assert(maxHeight == null || maxHeight > 0, 'maxHeight cannot be null'),
        assert(minHeight == null || minHeight >= 0, 'minHeight cannot be null'),
        assert(maxHeight == null || minHeight == null || maxHeight >= minHeight,
            'maxHeight cannot be null'),
        showCursor = showCursor ?? true,
        super(key: key);

  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool scrollable;
  final double scrollBottomInset;
  final EdgeInsetsGeometry padding;
  final bool readOnly;
  final String? placeholder;
  final ValueChanged<String>? onLaunchUrl;
  final ToolbarOptions toolbarOptions;
  final bool showSelectionHandles;
  final bool showCursor;
  final CursorStyle cursorStyle;
  final TextCapitalization textCapitalization;
  final double? maxHeight;
  final double? minHeight;
  final DefaultStyles? customStyles;
  final bool expands;
  final bool autoFocus;
  final Color selectionColor;
  final TextSelectionControls selectionCtrls;
  final Brightness keyboardAppearance;
  final bool enableInteractiveSelection;
  final ScrollPhysics? scrollPhysics;
  final EmbedBuilder embedBuilder;
  final CustomStyleBuilder? customStyleBuilder;
  @override
  State<StatefulWidget> createState() => RawEditorState();
}

class RawEditorState extends EditorState
    with
        AutomaticKeepAliveClientMixin<RawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<RawEditor>,
        RawEditorStateKeyboardMixin,
        RawEditorStateTextInputClientMixin,
        RawEditorStateSelectionDelegateMixin {
  final GlobalKey _editorKey = GlobalKey();

  // Keyboard
  late KeyboardEventHandler _keyboardListener;
  KeyboardVisibilityController? _keyboardVisibilityController;
  StreamSubscription<bool>? _keyboardVisibilitySubscription;
  bool _keyboardVisible = false;

  // Selection overlay
  @override
  EditorTextSelectionOverlay? getSelectionOverlay() => _selectionOverlay;
  EditorTextSelectionOverlay? _selectionOverlay;

  @override
  ScrollController get scrollController => _scrollController;
  late ScrollController _scrollController;

  late CursorCont _cursorCont;

  // Focus
  bool _didAutoFocus = false;
  FocusAttachment? _focusAttachment;
  bool get _hasFocus => widget.focusNode.hasFocus;

  DefaultStyles? _styles;

  final ClipboardStatusNotifier _clipboardStatus = ClipboardStatusNotifier();
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  TextDirection get _textDirection => Directionality.of(context);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _focusAttachment!.reparent();
    super.build(context);

    var _doc = widget.controller.document;
    if (_doc.isEmpty() && widget.placeholder != null) {
      _doc = Document.fromJson(jsonDecode(
          '[{"attributes":{"placeholder":true},"insert":"${widget.placeholder}\\n"}]'));
    }

    Widget child = CompositedTransformTarget(
      link: _toolbarLayerLink,
      child: Semantics(
        child: _Editor(
          key: _editorKey,
          document: _doc,
          selection: widget.controller.selection,
          hasFocus: _hasFocus,
          textDirection: _textDirection,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          onSelectionChanged: _handleSelectionChanged,
          scrollBottomInset: widget.scrollBottomInset,
          padding: widget.padding,
          children: _buildChildren(_doc, context),
        ),
      ),
    );

    if (widget.scrollable) {
      final baselinePadding =
          EdgeInsets.only(top: _styles!.paragraph!.verticalSpacing.item1);
      child = BaselineProxy(
        textStyle: _styles!.paragraph!.style,
        padding: baselinePadding,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: widget.scrollPhysics,
          child: child,
        ),
      );
    }

    final constraints = widget.expands
        ? const BoxConstraints.expand()
        : BoxConstraints(
            minHeight: widget.minHeight ?? 0.0,
            maxHeight: widget.maxHeight ?? double.infinity);

    return QuillStyles(
      data: _styles!,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Container(
          constraints: constraints,
          child: child,
        ),
      ),
    );
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause cause) {
    widget.controller.updateSelection(selection, ChangeSource.LOCAL);

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();

    if (!_keyboardVisible) {
      requestKeyboard();
    }
  }

  /// Updates the checkbox positioned at [offset] in document
  /// by changing its attribute according to [value].
  void _handleCheckboxTap(int offset, bool value) {
    if (!widget.readOnly) {
      if (value) {
        widget.controller.formatText(offset, 0, Attribute.checked);
      } else {
        widget.controller.formatText(offset, 0, Attribute.unchecked);
      }
    }
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
            color: widget.selectionColor,
            styles: _styles,
            enableInteractiveSelection: widget.enableInteractiveSelection,
            hasFocus: _hasFocus,
            contentPadding: attrs.containsKey(Attribute.codeBlock.key)
                ? const EdgeInsets.all(16)
                : null,
            embedBuilder: widget.embedBuilder,
            cursorCont: _cursorCont,
            indentLevelCounts: indentLevelCounts,
            onCheckboxTap: _handleCheckboxTap,
            readOnly: widget.readOnly,
            customStyleBuilder: widget.customStyleBuilder);
        result.add(editableTextBlock);
      } else {
        throw StateError('Unreachable.');
      }
    }
    return result;
  }

  EditableTextLine _getEditableTextLineFromNode(
      Line node, BuildContext context) {
    final textLine = TextLine(
      line: node,
      textDirection: _textDirection,
      embedBuilder: widget.embedBuilder,
      customStyleBuilder: widget.customStyleBuilder,
      styles: _styles!,
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
        widget.selectionColor,
        widget.enableInteractiveSelection,
        _hasFocus,
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

  @override
  void initState() {
    super.initState();

    _clipboardStatus.addListener(_onChangedClipboardStatus);

    widget.controller.addListener(() {
      _didChangeTextEditingValue(widget.controller.ignoreFocusOnTextChange);
    });

    _scrollController = widget.scrollController;
    _scrollController.addListener(_updateSelectionOverlayForScroll);

    _cursorCont = CursorCont(
      show: ValueNotifier<bool>(widget.showCursor),
      style: widget.cursorStyle,
      tickerProvider: this,
    );

    _keyboardListener = KeyboardEventHandler(
      handleCursorMovement,
      handleShortcut,
      handleDelete,
    );

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.fuchsia) {
      _keyboardVisible = true;
    } else {
      _keyboardVisibilityController = KeyboardVisibilityController();
      _keyboardVisible = _keyboardVisibilityController!.isVisible;
      _keyboardVisibilitySubscription =
          _keyboardVisibilityController?.onChange.listen((visible) {
        _keyboardVisible = visible;
        if (visible) {
          _onChangeTextEditingValue();
        }
      });
    }

    _focusAttachment = widget.focusNode.attach(context,
        onKey: (node, event) => _keyboardListener.handleRawKeyEvent(event));
    widget.focusNode.addListener(_handleFocusChanged);
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
      _styles = _styles!.merge(widget.customStyles!);
    }

    if (!_didAutoFocus && widget.autoFocus) {
      FocusScope.of(context).autofocus(widget.focusNode);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateWidget(RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cursorCont.show.value = widget.showCursor;
    _cursorCont.style = widget.cursorStyle;

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      updateRemoteValueIfNeeded();
    }

    if (widget.scrollController != _scrollController) {
      _scrollController.removeListener(_updateSelectionOverlayForScroll);
      _scrollController = widget.scrollController;
      _scrollController.addListener(_updateSelectionOverlayForScroll);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context,
          onKey: (node, event) => _keyboardListener.handleRawKeyEvent(event));
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(textEditingValue);
    }

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();
    if (!shouldCreateInputConnection) {
      closeConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) {
        openConnectionIfNeeded();
      }
    }
  }

  bool _shouldShowSelectionHandles() {
    return widget.showSelectionHandles &&
        !widget.controller.selection.isCollapsed;
  }

  @override
  void dispose() {
    closeConnectionIfNeeded();
    _keyboardVisibilitySubscription?.cancel();
    assert(!hasConnection);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.controller.removeListener(_didChangeTextEditingValue);
    widget.focusNode.removeListener(_handleFocusChanged);
    _focusAttachment!.detach();
    _cursorCont.dispose();
    _clipboardStatus
      ..removeListener(_onChangedClipboardStatus)
      ..dispose();
    super.dispose();
  }

  void _updateSelectionOverlayForScroll() {
    _selectionOverlay?.markNeedsBuild();
  }

  void _didChangeTextEditingValue([bool ignoreFocus = false]) {
    if (kIsWeb) {
      _onChangeTextEditingValue(ignoreFocus);
      if (!ignoreFocus) {
        requestKeyboard();
      }
      return;
    }

    if (ignoreFocus || _keyboardVisible) {
      _onChangeTextEditingValue(ignoreFocus);
    } else {
      requestKeyboard();
      if (mounted) {
        setState(() {
          // Use widget.controller.value in build()
          // Trigger build and updateChildren
        });
      }
    }
  }

  void _onChangeTextEditingValue([bool ignoreCaret = false]) {
    updateRemoteValueIfNeeded();
    if (ignoreCaret) {
      return;
    }
    _showCaretOnScreen();
    _cursorCont.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    if (hasConnection) {
      _cursorCont
        ..stopCursorTimer(resetCharTicks: false)
        ..startCursorTimer();
    }

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateOrDisposeSelectionOverlayIfNeeded();
    });
    if (mounted) {
      setState(() {
        // Use widget.controller.value in build()
        // Trigger build and updateChildren
      });
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(textEditingValue);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    } else if (_hasFocus) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;

      _selectionOverlay = EditorTextSelectionOverlay(
        textEditingValue,
        false,
        context,
        widget,
        _toolbarLayerLink,
        _startHandleLayerLink,
        _endHandleLayerLink,
        getRenderEditor(),
        widget.selectionCtrls,
        this,
        DragStartBehavior.start,
        null,
        _clipboardStatus,
      );
      _selectionOverlay!.handlesVisible = _shouldShowSelectionHandles();
      _selectionOverlay!.showHandles();
    }
  }

  void _handleFocusChanged() {
    openOrCloseConnection();
    _cursorCont.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      WidgetsBinding.instance!.addObserver(this);
      _showCaretOnScreen();
    } else {
      WidgetsBinding.instance!.removeObserver(this);
    }
    updateKeepAlive();
  }

  void _onChangedClipboardStatus() {
    if (!mounted) return;
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
      // Trigger build and updateChildren
    });
  }

  bool _showCaretOnScreenScheduled = false;

  void _showCaretOnScreen() {
    if (!widget.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (widget.scrollable || _scrollController.hasClients) {
        _showCaretOnScreenScheduled = false;

        final renderEditor = getRenderEditor();
        if (renderEditor == null) {
          return;
        }

        final viewport = RenderAbstractViewport.of(renderEditor);
        final editorOffset =
            renderEditor.localToGlobal(const Offset(0, 0), ancestor: viewport);
        final offsetInViewport = _scrollController.offset + editorOffset.dy;

        final offset = renderEditor.getOffsetToRevealCursor(
          _scrollController.position.viewportDimension,
          _scrollController.offset,
          offsetInViewport,
        );

        if (offset != null) {
          _scrollController.animateTo(
            math.min(offset, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  @override
  RenderEditor? getRenderEditor() {
    return _editorKey.currentContext?.findRenderObject() as RenderEditor?;
  }

  @override
  TextEditingValue getTextEditingValue() {
    return widget.controller.plainTextEditingValue;
  }

  @override
  void requestKeyboard() {
    if (_hasFocus) {
      openConnectionIfNeeded();
      _showCaretOnScreen();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  @override
  void setTextEditingValue(TextEditingValue value) {
    if (value.text == textEditingValue.text) {
      widget.controller.updateSelection(value.selection, ChangeSource.LOCAL);
    } else {
      _setEditingValue(value);
    }
  }

  // set editing value from clipboard for mobile
  Future<void> _setEditingValue(TextEditingValue value) async {
    if (await _isItCut(value)) {
      widget.controller.replaceText(
        textEditingValue.selection.start,
        textEditingValue.text.length - value.text.length,
        '',
        value.selection,
      );
    } else {
      final value = textEditingValue;
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        final length =
            textEditingValue.selection.end - textEditingValue.selection.start;
        var str = data.text!;
        final codes = data.text!.codeUnits;
        // For clip from editor, it may contain image, a.k.a 65532.
        // For clip from browser, image is directly ignore.
        // Here we skip image when pasting.
        if (codes.contains(65532)) {
          final sb = StringBuffer();
          for (var i = 0; i < str.length; i++) {
            if (str.codeUnitAt(i) == 65532) {
              continue;
            }
            sb.write(str[i]);
          }
          str = sb.toString();
        }
        widget.controller.replaceText(
          value.selection.start,
          length,
          str,
          value.selection,
        );
        // move cursor to the end of pasted text selection
        widget.controller.updateSelection(
            TextSelection.collapsed(
                offset: value.selection.start + data.text!.length),
            ChangeSource.LOCAL);
      }
    }
  }

  Future<bool> _isItCut(TextEditingValue value) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return false;
    }
    return textEditingValue.text.length - value.text.length ==
        data.text!.length;
  }

  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }
    if (_selectionOverlay == null || _selectionOverlay!.toolbar != null) {
      return false;
    }

    _selectionOverlay!.update(textEditingValue);
    _selectionOverlay!.showToolbar();
    return true;
  }

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;
}

class _Editor extends MultiChildRenderObjectWidget {
  _Editor({
    required Key key,
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    required this.hasFocus,
    required this.selection,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.onSelectionChanged,
    required this.scrollBottomInset,
    this.padding = EdgeInsets.zero,
  }) : super(key: key, children: children);

  final Document document;
  final TextDirection textDirection;
  final bool hasFocus;
  final TextSelection selection;
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
      selection,
      hasFocus,
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
      ..setHasFocus(hasFocus)
      ..setSelection(selection)
      ..setStartHandleLayerLink(startHandleLayerLink)
      ..setEndHandleLayerLink(endHandleLayerLink)
      ..onSelectionChanged = onSelectionChanged
      ..setScrollBottomInset(scrollBottomInset)
      ..setPadding(padding);
  }
}
