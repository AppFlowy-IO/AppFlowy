import 'package:editor/flutter_quill.dart';
import 'package:editor/models/documents/style.dart';

import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowyToggleStyleButton extends StatefulWidget {
  final Attribute attribute;
  final Widget icon;
  final double iconSize;
  final QuillController controller;

  const FlowyToggleStyleButton({
    required this.attribute,
    required this.icon,
    required this.controller,
    this.iconSize = kDefaultIconSize,
    Key? key,
  }) : super(key: key);

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();
}

class _ToggleStyleButtonState extends State<FlowyToggleStyleButton> {
  bool? _isToggled;
  Style get _selectionStyle => widget.controller.getSelectionStyle();
  @override
  void initState() {
    super.initState();
    _isToggled = _getIsToggled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return FlowyIconButton(
      onPressed: _toggleAttribute,
      width: widget.iconSize * kIconButtonFactor,
      icon: widget.icon,
      highlightColor: _isToggled == true ? theme.shader5 : theme.shader6,
      hoverColor: theme.shader5,
    );
  }

  @override
  void didUpdateWidget(covariant FlowyToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled = _getIsToggled(_selectionStyle.attributes);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  void _didChangeEditingValue() {
    setState(() => _isToggled = _getIsToggled(_selectionStyle.attributes));
  }

  bool _getIsToggled(Map<String, Attribute> attrs) {
    if (widget.attribute.key == Attribute.list.key) {
      final attribute = attrs[widget.attribute.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == widget.attribute.value;
    }
    return attrs.containsKey(widget.attribute.key);
  }

  void _toggleAttribute() {
    widget.controller.formatSelection(_isToggled! ? Attribute.clone(widget.attribute, null) : widget.attribute);
  }
}
