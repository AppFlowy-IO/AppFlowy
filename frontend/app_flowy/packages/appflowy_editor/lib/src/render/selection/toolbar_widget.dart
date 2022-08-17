import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';

typedef ToolbarEventHandler = void Function(EditorState editorState);

typedef ToolbarEventHandlers = Map<String, ToolbarEventHandler>;

ToolbarEventHandlers defaultToolbarEventHandlers = {
  'bold': (editorState) => formatBold(editorState),
  'italic': (editorState) => formatItalic(editorState),
  'strikethrough': (editorState) => formatStrikethrough(editorState),
  'underline': (editorState) => formatUnderline(editorState),
  'quote': (editorState) => formatQuote(editorState),
  'bulleted_list': (editorState) => formatBulletedList(editorState),
  'highlight': (editorState) => formatHighlight(editorState),
  'Text': (editorState) => formatText(editorState),
  'h1': (editorState) => formatHeading(editorState, StyleKey.h1),
  'h2': (editorState) => formatHeading(editorState, StyleKey.h2),
  'h3': (editorState) => formatHeading(editorState, StyleKey.h3),
};

List<String> defaultListToolbarEventNames = [
  'Text',
  'H1',
  'H2',
  'H3',
];

mixin ToolbarMixin<T extends StatefulWidget> on State<T> {
  void hide();
}

class ToolbarWidget extends StatefulWidget {
  const ToolbarWidget({
    Key? key,
    required this.editorState,
    required this.layerLink,
    required this.offset,
    required this.handlers,
  }) : super(key: key);

  final EditorState editorState;
  final LayerLink layerLink;
  final Offset offset;
  final ToolbarEventHandlers handlers;

  @override
  State<ToolbarWidget> createState() => _ToolbarWidgetState();
}

class _ToolbarWidgetState extends State<ToolbarWidget> with ToolbarMixin {
  final GlobalKey _listToolbarKey = GlobalKey();

  final toolbarHeight = 32.0;
  final topPadding = 5.0;

  final listToolbarWidth = 60.0;
  final listToolbarHeight = 120.0;

  final cornerRadius = 8.0;

  OverlayEntry? _listToolbarOverlay;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.offset.dx,
      left: widget.offset.dy,
      child: CompositedTransformFollower(
        link: widget.layerLink,
        showWhenUnlinked: true,
        offset: widget.offset,
        child: _buildToolbar(context),
      ),
    );
  }

  @override
  void hide() {
    _listToolbarOverlay?.remove();
    _listToolbarOverlay = null;
  }

  Widget _buildToolbar(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(cornerRadius),
      color: const Color(0xFF333333),
      child: SizedBox(
        height: toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _listToolbar(context),
            _centerToolbarIcon('h1', tooltipMessage: 'Heading 1'),
            _centerToolbarIcon('h2', tooltipMessage: 'Heading 2'),
            _centerToolbarIcon('h3', tooltipMessage: 'Heading 3'),
            _centerToolbarIcon('divider', width: 2),
            _centerToolbarIcon('bold', tooltipMessage: 'Bold'),
            _centerToolbarIcon('italic', tooltipMessage: 'Italic'),
            _centerToolbarIcon('strikethrough',
                tooltipMessage: 'Strikethrough'),
            _centerToolbarIcon('underline', tooltipMessage: 'Underline'),
            _centerToolbarIcon('divider', width: 2),
            _centerToolbarIcon('quote', tooltipMessage: 'Quote'),
            // _centerToolbarIcon('number_list'),
            _centerToolbarIcon('bulleted_list',
                tooltipMessage: 'Bulleted List'),
            _centerToolbarIcon('divider', width: 2),
            _centerToolbarIcon('highlight', tooltipMessage: 'Highlight'),
          ],
        ),
      ),
    );
  }

  Widget _listToolbar(BuildContext context) {
    return _centerToolbarIcon(
      'quote',
      key: _listToolbarKey,
      width: listToolbarWidth,
      onTap: () => _onTapListToolbar(context),
    );
  }

  Widget _centerToolbarIcon(String name,
      {Key? key, String? tooltipMessage, double? width, VoidCallback? onTap}) {
    return Tooltip(
        key: key,
        preferBelow: false,
        message: tooltipMessage ?? '',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap ?? () => _onTap(name),
            child: SizedBox.fromSize(
              size:
                  Size(toolbarHeight - (width != null ? 20 : 0), toolbarHeight),
              child: Center(
                child: FlowySvg(
                  size: Size(width ?? 20, 20),
                  name: 'toolbar/$name',
                ),
              ),
            ),
          ),
        ));
  }

  void _onTapListToolbar(BuildContext context) {
    // TODO: implement more detailed UI.
    final items = defaultListToolbarEventNames;
    final renderBox =
        _listToolbarKey.currentContext?.findRenderObject() as RenderBox;
    final offset = renderBox
        .localToGlobal(Offset.zero)
        .translate(0, toolbarHeight - cornerRadius);
    final rect = offset & Size(listToolbarWidth, listToolbarHeight);

    _listToolbarOverlay?.remove();
    _listToolbarOverlay = OverlayEntry(builder: (context) {
      return Positioned.fromRect(
        rect: rect,
        child: Material(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(cornerRadius),
            bottomRight: Radius.circular(cornerRadius),
          ),
          color: const Color(0xFF333333),
          child: SingleChildScrollView(
            child: ListView.builder(
              itemExtent: toolbarHeight,
              padding: const EdgeInsets.only(bottom: 10.0),
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: ((context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(
                    left: 3.0,
                    right: 3.0,
                  ),
                  minVerticalPadding: 0.0,
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      items[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () {
                    _onTap(items[index]);
                  },
                );
              }),
            ),
          ),
        ),
      );
    });
    // TODO: disable scrolling.
    Overlay.of(context)?.insert(_listToolbarOverlay!);
  }

  void _onTap(String eventName) {
    if (defaultToolbarEventHandlers.containsKey(eventName)) {
      defaultToolbarEventHandlers[eventName]!(widget.editorState);
      return;
    }
    assert(false, 'Could not find the event handler for $eventName');
  }
}
