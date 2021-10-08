import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../controller.dart';
import '../toolbar.dart';

class SelectHeaderStyleButton extends StatefulWidget {
  const SelectHeaderStyleButton({
    required this.controller,
    this.iconSize = kDefaultIconSize,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final double iconSize;

  @override
  _SelectHeaderStyleButtonState createState() =>
      _SelectHeaderStyleButtonState();
}

class _SelectHeaderStyleButtonState extends State<SelectHeaderStyleButton> {
  Attribute? _value;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    setState(() {
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <Attribute, String>{
      Attribute.header: 'N',
      Attribute.h1: 'H1',
      Attribute.h2: 'H2',
      Attribute.h3: 'H3',
    };

    final _valueAttribute = <Attribute>[
      Attribute.header,
      Attribute.h1,
      Attribute.h2,
      Attribute.h3
    ];
    final _valueString = <String>['N', 'H1', 'H2', 'H3'];

    final theme = Theme.of(context);
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: widget.iconSize * 0.7,
    );

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
              onPressed: () =>
                  widget.controller.formatSelection(_valueAttribute[index]),
              child: Text(
                _valueString[index],
                style: style.copyWith(
                  color: _valueToText[_value] == _valueString[index]
                      ? theme.primaryIconTheme.color
                      : theme.iconTheme.color,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    });
  }

  @override
  void didUpdateWidget(covariant SelectHeaderStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }
}
