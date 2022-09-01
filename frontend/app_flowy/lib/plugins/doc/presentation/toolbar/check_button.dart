import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/models/documents/style.dart';
import 'package:flutter/material.dart';

import 'toolbar_icon_button.dart';

class FlowyCheckListButton extends StatefulWidget {
  const FlowyCheckListButton({
    required this.controller,
    required this.attribute,
    required this.tooltipText,
    this.iconSize = defaultIconSize,
    this.fillColor,
    this.childBuilder = defaultToggleStyleButtonBuilder,
    Key? key,
  }) : super(key: key);

  final double iconSize;

  final Color? fillColor;

  final QuillController controller;

  final ToggleStyleButtonBuilder childBuilder;

  final Attribute attribute;

  final String tooltipText;

  @override
  FlowyCheckListButtonState createState() => FlowyCheckListButtonState();
}

class FlowyCheckListButtonState extends State<FlowyCheckListButton> {
  bool? _isToggled;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          _getIsToggled(widget.controller.getSelectionStyle().attributes);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggled = _getIsToggled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggled(Map<String, Attribute> attrs) {
    if (widget.attribute.key == Attribute.list.key) {
      final attribute = attrs[widget.attribute.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == widget.attribute.value ||
          attribute.value == Attribute.checked.value;
    }
    return attrs.containsKey(widget.attribute.key);
  }

  @override
  void didUpdateWidget(covariant FlowyCheckListButton oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return ToolbarIconButton(
      onPressed: _toggleAttribute,
      width: widget.iconSize * kIconButtonFactor,
      iconName: 'editor/checkbox',
      isToggled: _isToggled ?? false,
      tooltipText: widget.tooltipText,
    );
  }

  void _toggleAttribute() {
    widget.controller.formatSelection(_isToggled!
        ? Attribute.clone(Attribute.unchecked, null)
        : Attribute.unchecked);
  }
}
