import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../controller.dart';
import '../toolbar.dart';

class SelectAlignmentButton extends StatefulWidget {
  const SelectAlignmentButton({
    required this.controller,
    this.iconSize = kDefaultIconSize,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final double iconSize;

  @override
  _SelectAlignmentButtonState createState() => _SelectAlignmentButtonState();
}

class _SelectAlignmentButtonState extends State<SelectAlignmentButton> {
  Attribute? _value;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    setState(() {
      _value = _selectionStyle.attributes[Attribute.align.key] ??
          Attribute.leftAlignment;
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <Attribute, String>{
      Attribute.leftAlignment: Attribute.leftAlignment.value!,
      Attribute.centerAlignment: Attribute.centerAlignment.value!,
      Attribute.rightAlignment: Attribute.rightAlignment.value!,
      Attribute.justifyAlignment: Attribute.justifyAlignment.value!,
    };

    final _valueAttribute = <Attribute>[
      Attribute.leftAlignment,
      Attribute.centerAlignment,
      Attribute.rightAlignment,
      Attribute.justifyAlignment
    ];
    final _valueString = <String>[
      Attribute.leftAlignment.value!,
      Attribute.centerAlignment.value!,
      Attribute.rightAlignment.value!,
      Attribute.justifyAlignment.value!,
    ];

    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: !kIsWeb ? 1.0 : 5.0),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: widget.iconSize * kIconButtonFactor,
              height: widget.iconSize * kIconButtonFactor,
            ),
            child: RawMaterialButton(
              hoverElevation: 0,
              highlightElevation: 0,
              elevation: 0,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
              fillColor: _valueToText[_value] == _valueString[index]
                  ? theme.toggleableActiveColor
                  : theme.canvasColor,
              onPressed: () => _valueAttribute[index] == Attribute.leftAlignment
                  ? widget.controller
                      .formatSelection(Attribute.clone(Attribute.align, null))
                  : widget.controller.formatSelection(_valueAttribute[index]),
              child: Icon(
                _valueString[index] == Attribute.leftAlignment.value
                    ? Icons.format_align_left
                    : _valueString[index] == Attribute.centerAlignment.value
                        ? Icons.format_align_center
                        : _valueString[index] == Attribute.rightAlignment.value
                            ? Icons.format_align_right
                            : Icons.format_align_justify,
                size: widget.iconSize,
                color: _valueToText[_value] == _valueString[index]
                    ? theme.primaryIconTheme.color
                    : theme.iconTheme.color,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _value = _selectionStyle.attributes[Attribute.align.key] ??
          Attribute.leftAlignment;
    });
  }

  @override
  void didUpdateWidget(covariant SelectAlignmentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value = _selectionStyle.attributes[Attribute.align.key] ??
          Attribute.leftAlignment;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }
}
