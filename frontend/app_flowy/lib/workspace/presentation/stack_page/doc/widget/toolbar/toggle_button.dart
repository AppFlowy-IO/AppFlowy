import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/models/documents/style.dart';
import 'package:flutter/material.dart';

import 'toolbar_icon_button.dart';

class FlowyToggleStyleButton extends StatefulWidget {
  final Attribute attribute;
  final String normalIcon;
  final double iconSize;
  final QuillController controller;
  final String tooltipText;

  const FlowyToggleStyleButton({
    required this.attribute,
    required this.normalIcon,
    required this.controller,
    required this.tooltipText,
    this.iconSize = defaultIconSize,
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
    return ToolbarIconButton(
      onPressed: _toggleAttribute,
      width: widget.iconSize * kIconButtonFactor,
      isToggled: _isToggled ?? false,
      iconName: widget.normalIcon,
      tooltipText: widget.tooltipText,
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
