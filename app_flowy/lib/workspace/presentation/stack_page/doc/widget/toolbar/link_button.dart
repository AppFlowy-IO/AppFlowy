import 'package:editor/flutter_quill.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowyLinkStyleButton extends StatefulWidget {
  const FlowyLinkStyleButton({
    required this.controller,
    this.iconSize = kDefaultIconSize,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final double iconSize;

  @override
  _FlowyLinkStyleButtonState createState() => _FlowyLinkStyleButtonState();
}

class _FlowyLinkStyleButtonState extends State<FlowyLinkStyleButton> {
  void _didChangeSelection() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeSelection);
  }

  @override
  void didUpdateWidget(covariant FlowyLinkStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeSelection);
      widget.controller.addListener(_didChangeSelection);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_didChangeSelection);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.controller.selection.isCollapsed;
    final pressedHandler = isEnabled ? () => _openLinkDialog(context) : null;

    final theme = context.watch<AppTheme>();

    return FlowyIconButton(
      onPressed: pressedHandler,
      icon: svg('editor/share'),
      highlightColor: isEnabled == true ? theme.shader5 : theme.shader6,
      hoverColor: theme.shader5,
      width: widget.iconSize * kIconButtonFactor,
    );
  }

  void _openLinkDialog(BuildContext context) {
    // showDialog<String>(
    //   context: context,
    //   builder: (ctx) {
    //     return const LinkDialog();
    //   },
    // ).then(_linkSubmitted);
  }

  void _linkSubmitted(String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    widget.controller.formatSelection(LinkAttribute(value));
  }
}
