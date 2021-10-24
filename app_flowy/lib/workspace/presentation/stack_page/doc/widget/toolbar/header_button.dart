import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/models/documents/style.dart';
import 'package:flutter/material.dart';

import 'toolbar_icon_button.dart';

class FlowyHeaderStyleButton extends StatefulWidget {
  const FlowyHeaderStyleButton({
    required this.controller,
    this.iconSize = defaultIconSize,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final double iconSize;

  @override
  _FlowyHeaderStyleButtonState createState() => _FlowyHeaderStyleButtonState();
}

class _FlowyHeaderStyleButtonState extends State<FlowyHeaderStyleButton> {
  Attribute? _value;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    setState(() {
      _value = _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <Attribute, String>{
      Attribute.h1: 'H1',
      Attribute.h2: 'H2',
      Attribute.h3: 'H3',
    };

    final _valueAttribute = <Attribute>[Attribute.h1, Attribute.h2, Attribute.h3];
    final _valueString = <String>['H1', 'H2', 'H3'];
    final _attributeImageName = <String>['editor/H1', 'editor/H2', 'editor/H3'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        // final child =
        //     _valueToText[_value] == _valueString[index] ? svg('editor/H1', color: Colors.white) : svg('editor/H1');

        final _isToggled = _valueToText[_value] == _valueString[index];
        return ToolbarIconButton(
          onPressed: () {
            if (_isToggled) {
              widget.controller.formatSelection(Attribute.header);
            } else {
              widget.controller.formatSelection(_valueAttribute[index]);
            }
          },
          width: widget.iconSize * kIconButtonFactor,
          iconName: _attributeImageName[index],
          isToggled: _isToggled,
        );
      }),
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _value = _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    });
  }

  @override
  void didUpdateWidget(covariant FlowyHeaderStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value = _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }
}
