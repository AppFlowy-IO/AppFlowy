import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'toolbar_icon_button.dart';

class FlowyLinkStyleButton extends StatefulWidget {
  const FlowyLinkStyleButton({
    required this.controller,
    this.iconSize = defaultIconSize,
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
    final theme = context.watch<AppTheme>();
    final isEnabled = !widget.controller.selection.isCollapsed;
    final pressedHandler = isEnabled ? () => _openLinkDialog(context) : null;
    final icon = isEnabled
        ? svgWidget(
            'editor/share',
            color: theme.iconColor,
          )
        : svgWidget(
            'editor/share',
            color: theme.disableIconColor,
          );

    return FlowyIconButton(
      onPressed: pressedHandler,
      iconPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      icon: icon,
      fillColor: theme.shader6,
      hoverColor: theme.shader5,
      width: widget.iconSize * kIconButtonFactor,
    );
  }

  void _openLinkDialog(BuildContext context) {
    final style = widget.controller.getSelectionStyle();
    final values = style.values.where((v) => v.key == Attribute.link.key).map((v) => v.value);
    String value = "";
    if (values.isNotEmpty) {
      assert(values.length == 1);
      value = values.first;
    }

    TextFieldDialog(
      title: 'URL',
      value: value,
      confirm: (newValue) {
        if (newValue.isEmpty) {
          return;
        }
        widget.controller.formatSelection(LinkAttribute(newValue));
      },
    ).show(context);
  }
}
