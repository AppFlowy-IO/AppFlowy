import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flutter/material.dart';

import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';
import 'package:flowy_editor/service/default_text_operations/format_rich_text_style.dart';

typedef ToolbarEventHandler = void Function(EditorState editorState);

typedef ToolbarEventHandlers = Map<String, ToolbarEventHandler>;

ToolbarEventHandlers defaultToolbarEventHandlers = {
  'bold': (editorState) => formatBold(editorState),
  'italic': (editorState) => formatItalic(editorState),
  'strikethrough': (editorState) => formatStrikethrough(editorState),
  'underline': (editorState) => formatUnderline(editorState),
  'quote': (editorState) => formatQuote(editorState),
  'number_list': (editorState) {},
  'bulleted_list': (editorState) => formatBulletedList(editorState),
  'Text': (editorState) => formatText(editorState),
  'H1': (editorState) => formatHeading(editorState, StyleKey.h1),
  'H2': (editorState) => formatHeading(editorState, StyleKey.h2),
  'H3': (editorState) => formatHeading(editorState, StyleKey.h3),
};

List<String> defaultListToolbarEventNames = [
  'Text',
  'H1',
  'H2',
  'H3',
  // 'B-List',
  // 'N-List',
];

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

class _ToolbarWidgetState extends State<ToolbarWidget> {
  final GlobalKey _listToolbarKey = GlobalKey();

  final toolbarHeight = 32.0;
  final topPadding = 5.0;

  final listToolbarWidth = 60.0;
  final listToolbarHeight = 120.0;

  final cornerRadius = 8.0;

  OverlayEntry? _listToolbarOverlay;

  @override
  void initState() {
    super.initState();

    widget.editorState.service.selectionService.currentSelection
        .addListener(_onSelectionChange);
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.currentSelection
        .removeListener(_onSelectionChange);
    super.dispose();
  }

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

  Widget _buildToolbar(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(cornerRadius),
      color: const Color(0xFF333333),
      child: SizedBox(
        height: toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _listToolbar(context),
            _centerToolbarIcon('divider', width: 10),
            _centerToolbarIcon('bold'),
            _centerToolbarIcon('italic'),
            _centerToolbarIcon('strikethrough'),
            _centerToolbarIcon('underline'),
            _centerToolbarIcon('divider', width: 10),
            _centerToolbarIcon('quote'),
            _centerToolbarIcon('number_list'),
            _centerToolbarIcon('bulleted_list'),
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
      {Key? key, double? width, VoidCallback? onTap}) {
    return Tooltip(
      key: key,
      preferBelow: false,
      message: name,
      child: GestureDetector(
        onTap: onTap ?? () => _onTap(name),
        child: SizedBox.fromSize(
          size: width != null
              ? Size(width, toolbarHeight)
              : Size.square(toolbarHeight),
          child: Center(
            child: FlowySvg(
              name: 'toolbar/$name',
            ),
          ),
        ),
      ),
    );
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

  void _onSelectionChange() {
    _listToolbarOverlay?.remove();
    _listToolbarOverlay = null;
  }
}
