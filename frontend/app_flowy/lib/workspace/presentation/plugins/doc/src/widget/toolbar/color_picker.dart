import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/models/documents/style.dart';
import 'package:flutter_quill/utils/color.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'toolbar_icon_button.dart';

class FlowyColorButton extends StatefulWidget {
  const FlowyColorButton({
    required this.icon,
    required this.controller,
    required this.background,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final double iconSize;
  final bool background;
  final QuillController controller;
  final QuillIconTheme? iconTheme;

  @override
  _FlowyColorButtonState createState() => _FlowyColorButtonState();
}

class _FlowyColorButtonState extends State<FlowyColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhitebackground;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor = _getIsToggledColor(widget.controller.getSelectionStyle().attributes);
      _isToggledBackground = _getIsToggledBackground(widget.controller.getSelectionStyle().attributes);
      _isWhite = _isToggledColor && _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhitebackground = _isToggledBackground && _selectionStyle.attributes['background']!.value == '#ffffff';
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor && _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhitebackground = _isToggledBackground && _selectionStyle.attributes['background']!.value == '#ffffff';
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggledColor(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.color.key);
  }

  bool _getIsToggledBackground(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.background.key);
  }

  @override
  void didUpdateWidget(covariant FlowyColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
      _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
      _isWhite = _isToggledColor && _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhitebackground = _isToggledBackground && _selectionStyle.attributes['background']!.value == '#ffffff';
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

    final fillColor = _isToggledColor && !widget.background && _isWhite
        ? stringToColor('#ffffff')
        : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor);
    final fillColorBackground = _isToggledBackground && widget.background && _isWhitebackground
        ? stringToColor('#ffffff')
        : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor);

    return Tooltip(
      message: LocaleKeys.toolbar_highlight.tr(),
      showDuration: Duration.zero,
      child: QuillIconButton(
        highlightElevation: 0,
        hoverElevation: 0,
        size: widget.iconSize * kIconButtonFactor,
        icon: Icon(widget.icon, size: widget.iconSize, color: theme.iconTheme.color),
        fillColor: widget.background ? fillColorBackground : fillColor,
        onPressed: _showColorPicker,
      ),
    );
  }

  void _changeColor(BuildContext context, Color color) {
    var hex = color.value.toRadixString(16);
    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }
    hex = '#$hex';
    widget.controller.formatSelection(widget.background ? BackgroundAttribute(hex) : ColorAttribute(hex));
    Navigator.of(context).pop();
  }

  void _showColorPicker() {
    // FlowyPoppuWindow.show(
    //   context,
    //   size: Size(600, 200),
    //   child: MaterialPicker(
    //     pickerColor: const Color(0x00000000),
    //     onColorChanged: (color) => _changeColor(context, color),
    //   ),
    // );

    final style = widget.controller.getSelectionStyle();
    final values = style.values.where((v) => v.key == Attribute.background.key).map((v) => v.value);
    int initialColor = 0;
    if (values.isNotEmpty) {
      assert(values.length == 1);
      initialColor = stringToHex(values.first);
    }

    StyledDialog(
      child: SingleChildScrollView(
        child: FlowyColorPicker(
          onColorChanged: (color) {
            if (color == null) {
              widget.controller.formatSelection(BackgroundAttribute(null));
              Navigator.of(context).pop();
            } else {
              _changeColor(context, color);
            }
          },
          initialColor: initialColor,
        ),
      ),
    ).show(context);
  }
}

int stringToHex(String code) {
  return int.parse(code.substring(1, 7), radix: 16) + 0xFF000000;
}

class FlowyColorPicker extends StatefulWidget {
  final List<int> colors = [
    0xffe8e0ff,
    0xffffe7fd,
    0xffffe7ee,
    0xffffefe3,
    0xfffff2cd,
    0xfff5ffdc,
    0xffddffd6,
    0xffdefff1,
  ];
  final Function(Color?) onColorChanged;
  final int initialColor;
  FlowyColorPicker({Key? key, required this.onColorChanged, this.initialColor = 0}) : super(key: key);

  @override
  State<FlowyColorPicker> createState() => _FlowyColorPickerState();
}

// if (shrinkWrap) {
//       innerContent = IntrinsicWidth(child: IntrinsicHeight(child: innerContent));
//     }
class _FlowyColorPickerState extends State<FlowyColorPicker> {
  @override
  Widget build(BuildContext context) {
    const double width = 480;
    const int crossAxisCount = 6;
    const double mainAxisSpacing = 10;
    const double crossAxisSpacing = 10;
    final numberOfRows = (widget.colors.length / crossAxisCount).ceil();

    const perRowHeight = ((width - ((crossAxisCount - 1) * mainAxisSpacing)) / crossAxisCount);
    final totalHeight = numberOfRows * perRowHeight + numberOfRows * crossAxisSpacing;

    return Container(
      constraints: BoxConstraints.tightFor(width: width, height: totalHeight),
      child: CustomScrollView(
        scrollDirection: Axis.vertical,
        controller: ScrollController(),
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (widget.colors.length > index) {
                  final isSelected = widget.colors[index] == widget.initialColor;
                  return ColorItem(
                    color: Color(widget.colors[index]),
                    onPressed: widget.onColorChanged,
                    isSelected: isSelected,
                  );
                } else {
                  return null;
                }
              },
              childCount: widget.colors.length,
            ),
          ),
        ],
      ),
    );
  }
}

class ColorItem extends StatelessWidget {
  final Function(Color?) onPressed;
  final bool isSelected;
  final Color color;
  const ColorItem({
    Key? key,
    required this.color,
    required this.onPressed,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isSelected) {
      return RawMaterialButton(
        onPressed: () {
          onPressed(color);
        },
        elevation: 0,
        hoverElevation: 0.6,
        fillColor: color,
        shape: const CircleBorder(),
      );
    } else {
      return RawMaterialButton(
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 8)) +
            CircleBorder(side: BorderSide(color: color, width: 4)),
        onPressed: () {
          if (isSelected) {
            onPressed(null);
          } else {
            onPressed(color);
          }
        },
        elevation: 1.0,
        hoverElevation: 0.6,
        fillColor: color,
      );
    }
  }
}
