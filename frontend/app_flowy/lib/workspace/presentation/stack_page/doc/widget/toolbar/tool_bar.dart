import 'dart:async';
import 'dart:math';

import 'package:app_flowy/workspace/presentation/stack_page/doc/widget/toolbar/history_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'check_button.dart';
import 'color_picker.dart';
import 'header_button.dart';
import 'link_button.dart';
import 'toggle_button.dart';
import 'toolbar_icon_button.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class EditorToolbar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> children;
  final double toolBarHeight;
  final Color? color;

  const EditorToolbar({
    required this.children,
    this.toolBarHeight = 46,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      constraints: BoxConstraints.tightFor(height: preferredSize.height),
      child: ToolbarButtonList(buttons: children).padding(horizontal: 4, vertical: 4),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolBarHeight);

  factory EditorToolbar.basic({
    required QuillController controller,
    double toolbarIconSize = defaultIconSize,
    OnImagePickCallback? onImagePickCallback,
    OnVideoPickCallback? onVideoPickCallback,
    MediaPickSettingSelector? mediaPickSettingSelector,
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
    WebVideoPickImpl? webVideoPickImpl,
    Key? key,
  }) {
    return EditorToolbar(
      key: key,
      toolBarHeight: toolbarIconSize * 2,
      children: [
        FlowyHistoryButton(
          icon: Icons.undo_outlined,
          iconSize: toolbarIconSize,
          controller: controller,
          undo: true,
          tooltipText: LocaleKeys.toolbar_undo.tr(),
        ),
        FlowyHistoryButton(
          icon: Icons.redo_outlined,
          iconSize: toolbarIconSize,
          controller: controller,
          undo: false,
          tooltipText: LocaleKeys.toolbar_redo.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.bold,
          normalIcon: 'editor/bold',
          iconSize: toolbarIconSize,
          controller: controller,
          tooltipText: LocaleKeys.toolbar_bold.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.italic,
          normalIcon: 'editor/italic',
          iconSize: toolbarIconSize,
          controller: controller,
          tooltipText: LocaleKeys.toolbar_italic.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.underline,
          normalIcon: 'editor/underline',
          iconSize: toolbarIconSize,
          controller: controller,
          tooltipText: LocaleKeys.toolbar_underline.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.strikeThrough,
          normalIcon: 'editor/strikethrough',
          iconSize: toolbarIconSize,
          controller: controller,
          tooltipText: LocaleKeys.toolbar_strike.tr(),
        ),
        FlowyColorButton(
          icon: Icons.format_color_fill,
          iconSize: toolbarIconSize,
          controller: controller,
          background: true,
        ),
        // FlowyImageButton(
        //   iconSize: toolbarIconSize,
        //   controller: controller,
        //   onImagePickCallback: onImagePickCallback,
        //   filePickImpl: filePickImpl,
        //   webImagePickImpl: webImagePickImpl,
        //   mediaPickSettingSelector: mediaPickSettingSelector,
        // ),
        FlowyHeaderStyleButton(
          controller: controller,
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.ol,
          controller: controller,
          normalIcon: 'editor/numbers',
          iconSize: toolbarIconSize,
          tooltipText: LocaleKeys.toolbar_numList.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.ul,
          controller: controller,
          normalIcon: 'editor/bullet_list',
          iconSize: toolbarIconSize,
          tooltipText: LocaleKeys.toolbar_bulletList.tr(),
        ),
        FlowyCheckListButton(
          attribute: Attribute.unchecked,
          controller: controller,
          iconSize: toolbarIconSize,
          tooltipText: LocaleKeys.toolbar_checkList.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.inlineCode,
          controller: controller,
          normalIcon: 'editor/inline_block',
          iconSize: toolbarIconSize,
          tooltipText: LocaleKeys.toolbar_inlineCode.tr(),
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.blockQuote,
          controller: controller,
          normalIcon: 'editor/quote',
          iconSize: toolbarIconSize,
          tooltipText: LocaleKeys.toolbar_quote.tr(),
        ),
        FlowyLinkStyleButton(
          controller: controller,
          iconSize: toolbarIconSize,
        ),
      ],
    );
  }
}

class ToolbarButtonList extends StatefulWidget {
  const ToolbarButtonList({required this.buttons, Key? key}) : super(key: key);

  final List<Widget> buttons;

  @override
  _ToolbarButtonListState createState() => _ToolbarButtonListState();
}

class _ToolbarButtonListState extends State<ToolbarButtonList> with WidgetsBindingObserver {
  final ScrollController _controller = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);

    // Listening to the WidgetsBinding instance is necessary so that we can
    // hide the arrows when the window gets a new size and thus the toolbar
    // becomes scrollable/unscrollable.
    WidgetsBinding.instance!.addObserver(this);

    // Workaround to allow the scroll controller attach to our ListView so that
    // we can detect if overflow arrows need to be shown on init.
    Timer.run(_handleScroll);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        List<Widget> children = [];
        double width = (widget.buttons.length + 2) * defaultIconSize * kIconButtonFactor;
        final isFit = constraints.maxWidth > width;
        if (!isFit) {
          children.add(_buildLeftArrow());
          width = width + 18;
        }

        children.add(_buildScrollableList(constraints, isFit));

        if (!isFit) {
          children.add(_buildRightArrow());
          width = width + 18;
        }

        return SizedBox(
          width: min(constraints.maxWidth, width),
          child: Row(
            children: children,
          ),
        );
      },
    );
  }

  @override
  void didChangeMetrics() => _handleScroll();

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    setState(() {
      _showLeftArrow = _controller.position.minScrollExtent != _controller.position.pixels;
      _showRightArrow = _controller.position.maxScrollExtent != _controller.position.pixels;
    });
  }

  Widget _buildLeftArrow() {
    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: _showLeftArrow ? const Icon(Icons.arrow_left, size: 18) : null,
      ),
    );
  }

  // [[sliver: https://medium.com/flutter/slivers-demystified-6ff68ab0296f]]
  Widget _buildScrollableList(BoxConstraints constraints, bool isFit) {
    Widget child = Expanded(
      child: CustomScrollView(
        scrollDirection: Axis.horizontal,
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return widget.buttons[index];
              },
              childCount: widget.buttons.length,
              addAutomaticKeepAlives: false,
            ),
          )
        ],
      ),
    );

    if (!isFit) {
      child = ScrollConfiguration(
        // Remove the glowing effect, as we already have the arrow indicators
        behavior: _NoGlowBehavior(),
        // The CustomScrollView is necessary so that the children are not
        // stretched to the height of the toolbar, https://bit.ly/3uC3bjI
        child: child,
      );
    }

    return child;
  }

  Widget _buildRightArrow() {
    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: _showRightArrow ? const Icon(Icons.arrow_right, size: 18) : null,
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext _, Widget child, AxisDirection __) {
    return child;
  }
}
