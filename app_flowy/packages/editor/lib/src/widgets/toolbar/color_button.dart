import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../../utils/color.dart';
import '../controller.dart';
import '../toolbar.dart';
import 'quill_icon_button.dart';

/// Controls color styles.
///
/// When pressed, this button displays overlay toolbar with
/// buttons for each color.
class ColorButton extends StatefulWidget {
  const ColorButton({
    required this.icon,
    required this.controller,
    required this.background,
    this.iconSize = kDefaultIconSize,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final double iconSize;
  final bool background;
  final QuillController controller;

  @override
  _ColorButtonState createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhitebackground;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor =
          _getIsToggledColor(widget.controller.getSelectionStyle().attributes);
      _isToggledBackground = _getIsToggledBackground(
          widget.controller.getSelectionStyle().attributes);
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhitebackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor &&
        _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhitebackground = _isToggledBackground &&
        _selectionStyle.attributes['background']!.value == '#ffffff';
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggledColor(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.color.key);
  }

  bool _getIsToggledBackground(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.background.key);
  }

  @override
  void didUpdateWidget(covariant ColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
      _isToggledBackground =
          _getIsToggledBackground(_selectionStyle.attributes);
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhitebackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _isToggledColor && !widget.background && !_isWhite
        ? stringToColor(_selectionStyle.attributes['color']!.value)
        : theme.iconTheme.color;

    final iconColorBackground =
        _isToggledBackground && widget.background && !_isWhitebackground
            ? stringToColor(_selectionStyle.attributes['background']!.value)
            : theme.iconTheme.color;

    final fillColor = _isToggledColor && !widget.background && _isWhite
        ? stringToColor('#ffffff')
        : theme.canvasColor;
    final fillColorBackground =
        _isToggledBackground && widget.background && _isWhitebackground
            ? stringToColor('#ffffff')
            : theme.canvasColor;

    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * kIconButtonFactor,
      icon: Icon(widget.icon,
          size: widget.iconSize,
          color: widget.background ? iconColorBackground : iconColor),
      fillColor: widget.background ? fillColorBackground : fillColor,
      onPressed: _showColorPicker,
    );
  }

  void _changeColor(BuildContext context, Color color) {
    var hex = color.value.toRadixString(16);
    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }
    hex = '#$hex';
    widget.controller.formatSelection(
        widget.background ? BackgroundAttribute(hex) : ColorAttribute(hex));
    Navigator.of(context).pop();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        backgroundColor: Theme.of(context).canvasColor,
        content: SingleChildScrollView(
          child: MaterialPicker(
            pickerColor: const Color(0x00000000),
            onColorChanged: (color) => _changeColor(context, color),
          ),
        ),
      ),
    );
  }
}
