import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widget/raw_editor.dart';
import '../widget/builder.dart';
import '../widget/embed.dart';
import '../widget/proxy.dart';
import '../model/document/attribute.dart';
import '../model/document/document.dart';
import '../model/document/node/line.dart';
import '../model/document/node/container.dart' as container_node;
import '../model/document/node/leaf.dart' show Leaf;
import '../service/controller.dart';
import '../service/cursor.dart';
import '../service/style.dart';

const linkPrefixes = [
  'mailto:', // email
  'tel:', // telephone
  'sms:', // SMS
  'callto:',
  'wtai:',
  'market:',
  'geopoint:',
  'ymsgr:',
  'msnim:',
  'gtalk:', // Google Talk
  'skype:',
  'sip:', // Lync
  'whatsapp:',
  'http'
];

/* ------------------------------ Flowy Editor ------------------------------ */

class FlowyEditor extends StatefulWidget {
  const FlowyEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.scrollable,
    required this.scrollBottomInset,
    required this.padding,
    required this.autoFocus,
    required this.readOnly,
    required this.expands,
    this.showCursor,
    this.placeholder,
    this.enableInteractiveSelection = true,
    this.minHeight,
    this.maxHeight,
    this.customStyles,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardAppearance = Brightness.light,
    this.scrollPhysics,
    this.onLaunchUrl,
    this.onTapDown,
    this.onTapUp,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.embedProvider = EmbedBaseProvider.buildEmbedWidget,
  });

  factory FlowyEditor.basic({
    required EditorController controller,
    required bool readOnly,
  }) {
    return FlowyEditor(
      controller: controller,
      focusNode: FocusNode(),
      scrollController: ScrollController(),
      scrollable: true,
      scrollBottomInset: 0,
      padding: EdgeInsets.zero,
      autoFocus: true,
      readOnly: readOnly,
      expands: false,
    );
  }

  final EditorController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool scrollable;
  final double scrollBottomInset;
  final EdgeInsetsGeometry padding;
  final bool autoFocus;
  final bool? showCursor;
  final bool readOnly;
  final String? placeholder;
  final bool enableInteractiveSelection;
  final double? minHeight;
  final double? maxHeight;
  final DefaultStyles? customStyles;
  final bool expands;
  final TextCapitalization textCapitalization;
  final Brightness keyboardAppearance;
  final ScrollPhysics? scrollPhysics;
  final EmbedBuilderFuncion embedProvider;

  // Callback

  final ValueChanged<String>? onLaunchUrl;

  /// Returns whether gesture is handled
  final bool Function(TapDownDetails details, TextPosition textPosition)? onTapDown;

  /// Returns whether gesture is handled
  final bool Function(TapUpDetails details, TextPosition textPosition)? onTapUp;

  /// Returns whether gesture is handled
  final bool Function(LongPressStartDetails details, TextPosition textPosition)? onLongPressStart;

  /// Returns whether gesture is handled
  final bool Function(LongPressMoveUpdateDetails details, TextPosition textPosition)? onLongPressMoveUpdate;

  /// Returns whether gesture is handled
  final bool Function(LongPressEndDetails details, TextPosition textPosition)? onLongPressEnd;

  @override
  _FlowyEditorState createState() => _FlowyEditorState();
}

class _FlowyEditorState extends State<FlowyEditor> implements EditorTextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  late EditorTextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder = _FlowyEditorSelectionGestureDetectorBuilder(this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset? cursorOffset;
    Color? cursorColor;
    Color selectionColor;
    Radius? cursorRadius;

    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor ??= selectionTheme.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionTheme.selectionColor ?? theme.colorScheme.primary.withOpacity(0.40);
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        final cupertinoTheme = CupertinoTheme.of(context);
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor ??= selectionTheme.cursorColor ?? cupertinoTheme.primaryColor;
        selectionColor = selectionTheme.selectionColor ?? cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2);
        cursorOffset = Offset(iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;
      default:
        throw UnimplementedError();
    }

    final showSelectionHandles = theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.android;

    return _selectionGestureDetectorBuilder.build(
      HitTestBehavior.translucent,
      RawEditor(
        _editorKey,
        widget.controller,
        widget.focusNode,
        widget.scrollController,
        widget.scrollable,
        widget.scrollBottomInset,
        widget.padding,
        widget.readOnly,
        widget.placeholder,
        widget.onLaunchUrl,
        ToolbarOptions(
          copy: widget.enableInteractiveSelection,
          cut: widget.enableInteractiveSelection,
          paste: widget.enableInteractiveSelection,
          selectAll: widget.enableInteractiveSelection,
        ),
        showSelectionHandles,
        widget.showCursor,
        CursorStyle(
          color: cursorColor,
          backgroundColor: Colors.grey,
          width: 2,
          radius: cursorRadius,
          offset: cursorOffset,
          paintAboveText: paintCursorAboveText,
          opacityAnimates: cursorOpacityAnimates,
        ),
        widget.textCapitalization,
        widget.maxHeight,
        widget.minHeight,
        widget.customStyles,
        widget.expands,
        widget.autoFocus,
        selectionColor,
        textSelectionControls,
        widget.keyboardAppearance,
        widget.enableInteractiveSelection,
        widget.scrollPhysics,
        widget.embedProvider,
      ),
    );
  }

  @override
  GlobalKey<EditorState> getEditableTextKey() => _editorKey;

  @override
  bool getForcePressEnabled() => false;

  @override
  bool getSelectionEnabled() => widget.enableInteractiveSelection;

  void _requestKeyboard() {
    _editorKey.currentState!.requestKeyboard();
  }
}

/* --------------------------------- Gesture -------------------------------- */

class _FlowyEditorSelectionGestureDetectorBuilder extends EditorTextSelectionGestureDetectorBuilder {
  _FlowyEditorSelectionGestureDetectorBuilder(this._state) : super(_state);

  final _FlowyEditorState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.getSelectionEnabled() && shouldShowSelectionToolbar) {
      getEditor()!.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {}

  @override
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_state.widget.onLongPressMoveUpdate != null) {
      final renderEditor = getRenderEditor();
      if (renderEditor != null) {
        if (_state.widget.onLongPressMoveUpdate!(details, renderEditor.getPositionForOffset(details.globalPosition))) {
          return;
        }
      }
    }
    if (!delegate.getSelectionEnabled()) {
      return;
    }

    switch (Theme.of(_state.context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        getRenderEditor()!.selectPositionAt(
          details.globalPosition,
          null,
          SelectionChangedCause.longPress,
        );
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        getRenderEditor()!.selectWordsInRange(
          details.globalPosition - details.offsetFromOrigin,
          details.globalPosition,
          SelectionChangedCause.longPress,
        );
        break;
      default:
        throw 'Invalid platform';
    }
  }

  @override
  void onTapDown(TapDownDetails details) {
    if (_state.widget.onTapDown != null) {
      final renderEditor = getRenderEditor();
      if (renderEditor != null) {
        if (_state.widget.onTapDown!(details, renderEditor.getPositionForOffset(details.globalPosition))) {
          return;
        }
      }
    }
    super.onTapDown(details);
  }

  @override
  void onTapUp(TapUpDetails details) {
    if (_state.widget.onTapUp != null) {
      final renderEditor = getRenderEditor();
      if (renderEditor != null) {
        if (_state.widget.onTapUp!(details, renderEditor.getPositionForOffset(details.globalPosition))) {
          return;
        }
      }
    }

    getEditor()!.hideToolbar();

    final positionSelected = _onTappingBlock(details);
    if (delegate.getSelectionEnabled() && !positionSelected) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              getRenderEditor()!.selectPosition(SelectionChangedCause.tap);
              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              getRenderEditor()!.selectWordEdge(SelectionChangedCause.tap);
              break;
          }
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          getRenderEditor()!.selectPosition(SelectionChangedCause.tap);
          break;
      }
    }
    _state._requestKeyboard();
  }

  @override
  void onLongPressStart(LongPressStartDetails details) {
    if (_state.widget.onLongPressStart != null) {
      final renderEditor = getRenderEditor();
      if (renderEditor != null) {
        if (_state.widget.onLongPressStart!(details, renderEditor.getPositionForOffset(details.globalPosition))) {
          return;
        }
      }
    }

    if (delegate.getSelectionEnabled()) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          getRenderEditor()!.selectPositionAt(
            details.globalPosition,
            null,
            SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          getRenderEditor()!.selectWord(SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
        default:
          throw 'Invalid platform';
      }
    }
  }

  @override
  void onLongPressEnd(LongPressEndDetails details) {
    if (_state.widget.onLongPressEnd != null) {
      final renderEditor = getRenderEditor();
      if (renderEditor != null) {
        if (_state.widget.onLongPressEnd!(details, renderEditor.getPositionForOffset(details.globalPosition))) {
          return;
        }
      }
      super.onLongPressEnd(details);
    }
  }

  // Util

  bool _onTappingBlock(TapUpDetails details) {
    if (_state.widget.controller.document.isEmpty()) {
      return false;
    }

    final position = getRenderEditor()!.getPositionForOffset(details.globalPosition);
    final result = getEditor()!.widget.controller.document.queryChild(position.offset);
    if (result.node == null) {
      return false;
    }

    final line = result.node as Line;
    final segmentResult = line.queryChild(result.offset, false);

    // Checkbox
    if (segmentResult.node == null) {
      if (line.length == 1) {
        // tapping when no text yet on this line
        _flipListCheckbox(position, line, segmentResult);
        getEditor()!.widget.controller.updateSelection(
              TextSelection.collapsed(offset: position.offset),
              ChangeSource.LOCAL,
            );
        return true;
      }
      return false;
    }

    // Link
    final segment = segmentResult.node as Leaf;
    if (segment.style.containsKey(Attribute.link.key)) {
      var launchUrl = getEditor()!.widget.onLaunchUrl;
      launchUrl ??= _launchUrl;
      String? link = segment.style.attributes[Attribute.link.key]!.value;
      if (getEditor()!.widget.readOnly && link != null) {
        link = link.trim();
        if (!linkPrefixes.any((linkPrefix) => link!.toLowerCase().startsWith(linkPrefix))) {
          link = 'https://$link';
        }
        launchUrl(link);
      }
      return false;
    }

    // Fallback
    if (_flipListCheckbox(position, line, segmentResult)) {
      return true;
    }
    return false;
  }

  bool _flipListCheckbox(TextPosition position, Line line, container_node.ChildQuery segmentResult) {
    if (getEditor()!.widget.readOnly || !line.style.containsKey(Attribute.list.key) || segmentResult.offset != 0) {
      return false;
    }

    // segmentResult.offset == 0 means tap at the beginning of the TextLine
    final String? listVal = line.style.attributes[Attribute.list.key]!.value;
    if (Attribute.unchecked.value == listVal) {
      getEditor()!.widget.controller.formatText(position.offset, 0, Attribute.checked);
    } else if (Attribute.checked.value == listVal) {
      getEditor()!.widget.controller.formatText(position.offset, 0, Attribute.unchecked);
    }
    getEditor()!.widget.controller.updateSelection(
          TextSelection.collapsed(offset: position.offset),
          ChangeSource.LOCAL,
        );
    return true;
  }

  Future<void> _launchUrl(String url) async {
    await launch(url);
  }
}
