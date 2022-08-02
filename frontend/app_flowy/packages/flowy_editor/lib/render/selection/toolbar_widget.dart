import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';
import 'package:flutter/material.dart';

typedef ToolbarEventHandler = void Function(
    EditorState editorState, String eventName);

typedef ToolbarEventHandlers = List<Map<String, ToolbarEventHandler>>;
ToolbarEventHandlers defaultToolbarEventHandlers = [
  {
    'bold': ((editorState, eventName) {}),
    'italic': ((editorState, eventName) {}),
    'strikethrough': ((editorState, eventName) {}),
    'underline': ((editorState, eventName) {}),
    'quote': ((editorState, eventName) {}),
    'number_list': ((editorState, eventName) {}),
    'bulleted_list': ((editorState, eventName) {}),
  }
];

ToolbarEventHandlers defaultListToolbarEventHandlers = [
  {
    'h1': ((editorState, eventName) {}),
  },
  {
    'h2': ((editorState, eventName) {}),
  },
  {
    'h3': ((editorState, eventName) {}),
  },
  {
    'bulleted_list': ((editorState, eventName) {}),
  },
  {
    'quote': ((editorState, eventName) {}),
  }
];

class ToolbarWidget extends StatefulWidget {
  ToolbarWidget({
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

    widget.editorState.service.selectionService.currentSelectedNodes
        .addListener(_onSelectionChange);
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.currentSelectedNodes
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
        onTap: onTap ?? () => debugPrint('toolbar tap $name'),
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
    final items = defaultListToolbarEventHandlers
        .map((handler) => handler.keys.first)
        .toList(growable: false);
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
                    debugPrint('tap on $index');
                  },
                );
              }),
            ),
          ),
        ),
      );
    });
    Overlay.of(context)?.insert(_listToolbarOverlay!);
  }

  void _onSelectionChange() {
    _listToolbarOverlay?.remove();
    _listToolbarOverlay = null;
  }
}
