import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../model/document/style.dart';
import '../model/document/attribute.dart';
import '../model/document/node/embed.dart';
import '../util/color.dart';
import '../service/controller.dart';
import 'toolbar.dart';

/* -------------------------------- Constant -------------------------------- */

const double kToolbarIconHeight = 18.0;
const double kToolbarButtonHeight = kToolbarIconHeight * 1.77;

class FlowyToolbar extends EditorToolbar {
  const FlowyToolbar({
    required List<Widget> children,
    Key? key,
  }) : super(
          children: children,
          customButtonHeight: kToolbarButtonHeight,
          key: key,
        );

  factory FlowyToolbar.basic({
    required EditorController controller,
    double? toolbarIconSize,
    bool showHistory = true,
    bool showBold = true,
    bool showItalic = true,
    bool showUnderline = true,
    bool showStrikethrough = true,
    bool showColor = true,
    bool showBackgroundColor = true,
    bool showClearFormat = true,
    bool showHeader = true,
    bool showBulletList = true,
    bool showOrderedList = true,
    bool showCheckList = true,
    bool showCodeblock = true,
    bool showQuoteblock = true,
    bool showIndent = true,
    bool showLink = true,
    bool showHorizontalLine = true,
    OnImageSelectCallback? onImageSelectCallback,
    Key? key,
  }) {
    return FlowyToolbar(children: [
      Visibility(
        visible: showHistory,
        child: HistoryButton(
          icon: Icons.undo_outlined,
          controller: controller,
          isUndo: true,
        ),
      ),
      Visibility(
        visible: showHistory,
        child: HistoryButton(
          icon: Icons.redo_outlined,
          controller: controller,
          isUndo: false,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showBold,
        child: ToggleStyleButton(
          attribute: Attribute.bold,
          icon: Icons.format_bold,
          controller: controller,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showItalic,
        child: ToggleStyleButton(
          attribute: Attribute.italic,
          icon: Icons.format_italic,
          controller: controller,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showUnderline,
        child: ToggleStyleButton(
          attribute: Attribute.underline,
          icon: Icons.format_underline,
          controller: controller,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showStrikethrough,
        child: ToggleStyleButton(
          attribute: Attribute.strikeThrough,
          icon: Icons.format_strikethrough,
          controller: controller,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showColor,
        child: ColorButton(
          icon: Icons.color_lens,
          controller: controller,
          isBackground: false,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showColor,
        child: ColorButton(
          icon: Icons.format_color_fill,
          controller: controller,
          isBackground: true,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showColor,
        child: ClearFormatButton(
          icon: Icons.format_clear,
          controller: controller,
        ),
      ),
      const SizedBox(width: 0.6),
      Visibility(
        visible: showOrderedList,
        child: ToggleStyleButton(
          attribute: Attribute.ordered,
          icon: Icons.format_list_numbered,
          controller: controller,
        ),
      ),
      Visibility(
        visible: showBulletList,
        child: ToggleStyleButton(
          attribute: Attribute.bullet,
          icon: Icons.format_list_bulleted,
          controller: controller,
        ),
      ),
      Visibility(
        visible: showCheckList,
        child: ToggleStyleButton(
          attribute: Attribute.unchecked,
          icon: Icons.check_box,
          controller: controller,
        ),
      ),
      Visibility(
        visible: showCodeblock,
        child: ToggleStyleButton(
          attribute: Attribute.codeBlock,
          icon: Icons.code,
          controller: controller,
        ),
      ),
      Visibility(
        visible: showHeader,
        child: VerticalDivider(
            indent: 12, endIndent: 12, color: Colors.grey.shade400),
      ),
      Visibility(
        visible: showHeader,
        child: HeaderStyleButton(controller: controller),
      ),
      VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade400),
      Visibility(
        visible: !showOrderedList &&
            !showBulletList &&
            !showCheckList &&
            !showCodeblock,
        child: VerticalDivider(
            indent: 12, endIndent: 12, color: Colors.grey.shade400),
      ),
      Visibility(
        visible: showQuoteblock,
        child: ToggleStyleButton(
          attribute: Attribute.quoteBlock,
          controller: controller,
          icon: Icons.format_quote,
        ),
      ),
      Visibility(
        visible: showIndent,
        child: IndentButton(
          icon: Icons.format_indent_increase,
          controller: controller,
          isIncrease: true,
        ),
      ),
      Visibility(
        visible: showIndent,
        child: IndentButton(
          icon: Icons.format_indent_decrease,
          controller: controller,
          isIncrease: false,
        ),
      ),
      Visibility(
        visible: showQuoteblock,
        child: VerticalDivider(
            indent: 12, endIndent: 12, color: Colors.grey.shade400),
      ),
      Visibility(
        visible: showLink,
        child: LinkStyleButton(
          controller: controller,
          icon: Icons.link,
        ),
      ),
    ]);
  }
}

/* ---------------------------------- Util ---------------------------------- */

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    this.onPressed,
    this.icon,
    this.size = 40,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget? icon;
  final double size;
  final Color? fillColor;
  final double hoverElevation;
  final double highlightElevation;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: size, height: size),
      child: RawMaterialButton(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        fillColor: fillColor,
        elevation: 0,
        hoverElevation: hoverElevation,
        highlightElevation: hoverElevation,
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}

/* ------------------------------- Button Impl ------------------------------ */

// History (Redo, Undo)
class HistoryButton extends StatefulWidget {
  const HistoryButton({
    required this.icon,
    required this.isUndo,
    required this.controller,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final bool isUndo;
  final EditorController controller;

  @override
  _HistoryButtonState createState() => _HistoryButtonState();
}

class _HistoryButtonState extends State<HistoryButton> {
  Color? _iconColor;
  late ThemeData theme;

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    _setIconColor();

    final fillColor = theme.canvasColor;
    widget.controller.changes.listen((event) async {
      _setIconColor();
    });
    return ToolbarIconButton(
      size: kToolbarButtonHeight,
      fillColor: fillColor,
      hoverElevation: 0,
      highlightElevation: 0,
      icon: Icon(widget.icon, size: kToolbarIconHeight, color: _iconColor),
      onPressed: _applyHistory,
    );
  }

  void _applyHistory() {
    if (widget.isUndo) {
      if (widget.controller.hasUndo) {
        widget.controller.undo();
      }
    } else {
      if (widget.controller.hasRedo) {
        widget.controller.redo();
      }
    }
    _setIconColor();
  }

  void _setIconColor() {
    if (!mounted) {
      return;
    }

    if (widget.isUndo) {
      setState(() {
        _iconColor = widget.controller.hasUndo
            ? theme.iconTheme.color
            : theme.disabledColor;
      });
    } else {
      setState(() {
        _iconColor = widget.controller.hasRedo
            ? theme.iconTheme.color
            : theme.disabledColor;
      });
    }
  }
}

// Toggle Style (Bold, Italic, Underline, etc..)

typedef ToggleStyleButtonBuilder = Widget Function(
  BuildContext context,
  Attribute attribute,
  IconData icon,
  Color? fillColor,
  bool? isToggled,
  VoidCallback? onPressed,
);

Widget defaultToggleStyleButtonBuilder(
  BuildContext context,
  Attribute attribute,
  IconData icon,
  Color? fillColor,
  bool? isToggled,
  VoidCallback? onPressed,
) {
  final theme = Theme.of(context);
  final isEnabled = onPressed != null;
  final iconColor = isEnabled
      ? isToggled == true
          ? theme.primaryIconTheme.color
          : theme.iconTheme.color
      : theme.disabledColor;
  final theFillColor = isToggled == true
      ? theme.toggleableActiveColor
      : fillColor ?? theme.canvasColor;
  return ToolbarIconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: kToolbarIconHeight, color: iconColor),
    size: kToolbarButtonHeight,
    fillColor: theFillColor,
    hoverElevation: 0,
    highlightElevation: 0,
  );
}

class ToggleStyleButton extends StatefulWidget {
  const ToggleStyleButton({
    required this.attribute,
    required this.icon,
    required this.controller,
    this.fillColor,
    this.childBuilder = defaultToggleStyleButtonBuilder,
    Key? key,
  }) : super(key: key);

  final Attribute attribute;
  final IconData icon;
  final Color? fillColor;
  final EditorController controller;
  final ToggleStyleButtonBuilder childBuilder;

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();
}

class _ToggleStyleButtonState extends State<ToggleStyleButton> {
  bool? _isToggled;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void didUpdateWidget(covariant ToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled = _checkIfAttrToggled(_selectionStyle.attributes);
    }
  }

  @override
  void initState() {
    super.initState();
    _isToggled = _checkIfAttrToggled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInCodeBlock =
        _selectionStyle.attributes.containsKey(Attribute.codeBlock.key);
    final isEnabled =
        !isInCodeBlock || widget.attribute.key == Attribute.codeBlock.key;
    return widget.childBuilder(
      context,
      widget.attribute,
      widget.icon,
      widget.fillColor,
      _isToggled,
      isEnabled ? _toggleAttribute : null,
    );
  }

  bool _checkIfAttrToggled(Map<String, Attribute> attrs) {
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
    widget.controller.formatSelection(
      _isToggled! ? Attribute.clone(widget.attribute, null) : widget.attribute,
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          _checkIfAttrToggled(widget.controller.getSelectionStyle().attributes);
    });
  }
}

// Header Style

class HeaderStyleButton extends StatefulWidget {
  const HeaderStyleButton({
    required this.controller,
    Key? key,
  }) : super(key: key);

  final EditorController controller;
  @override
  _HeaderStyleButtonState createState() => _HeaderStyleButtonState();
}

class _HeaderStyleButtonState extends State<HeaderStyleButton> {
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
  void didUpdateWidget(covariant HeaderStyleButton oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return _selectHeaderStyleButtonBuilder(context, _value);
  }

  void _didChangeEditingValue() {
    setState(() {
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    });
  }

  Widget _selectHeaderStyleButtonBuilder(
      BuildContext context, Attribute? value) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: kToolbarIconHeight * 0.7,
    );

    final headerTextMapping = <Attribute, String>{
      Attribute.header: 'N',
      Attribute.h1: 'H1',
      Attribute.h2: 'H2',
      Attribute.h3: 'H3',
      Attribute.h4: 'H4',
      Attribute.h5: 'H5',
      Attribute.h6: 'H6',
    };
    final headerStyles = headerTextMapping.keys.toList(growable: false);
    final headerTexts = headerTextMapping.values.toList(growable: false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(headerStyles.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: !kIsWeb ? 1.0 : 5.0),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
                width: kToolbarButtonHeight, height: kToolbarButtonHeight),
            child: RawMaterialButton(
              fillColor: headerTextMapping[value] == headerTexts[index]
                  ? theme.toggleableActiveColor
                  : theme.canvasColor,
              hoverElevation: 0,
              highlightElevation: 0,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
              onPressed: () {
                widget.controller.formatSelection(headerStyles[index]);
              },
              child: Text(
                headerTexts[index],
                style: style.copyWith(
                  color: headerTextMapping[value] == headerTexts[index]
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
}

// Color (TextColor, BackgroundColor)

class ColorButton extends StatefulWidget {
  const ColorButton({
    required this.icon,
    required this.isBackground,
    required this.controller,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final bool isBackground;
  final EditorController controller;

  @override
  _ColorButtonState createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhiteBackground;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void didUpdateWidget(covariant ColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _updateToggledState();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateToggledState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _isToggledColor && !widget.isBackground && !_isWhite
        ? stringToColor(_selectionStyle.attributes['color']!.value)
        : theme.iconTheme.color;
    final iconColorBackground =
        _isToggledBackground && widget.isBackground && !_isWhiteBackground
            ? stringToColor(_selectionStyle.attributes['background']!.value)
            : theme.iconTheme.color;
    final fillColor = _isToggledColor && !widget.isBackground && _isWhite
        ? stringToColor('#ffffff')
        : theme.canvasColor;
    final fillColorBackground =
        _isToggledBackground && widget.isBackground && _isWhiteBackground
            ? stringToColor('#ffffff')
            : theme.canvasColor;

    return ToolbarIconButton(
      size: kToolbarButtonHeight,
      fillColor: widget.isBackground ? fillColorBackground : fillColor,
      hoverElevation: 0,
      highlightElevation: 0,
      icon: Icon(
        widget.icon,
        size: kToolbarIconHeight,
        color: widget.isBackground ? iconColorBackground : iconColor,
      ),
      onPressed: _showColorPicker,
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _updateToggledState();
      widget.controller.addListener(_didChangeEditingValue);
    });
  }

  void _updateToggledState() {
    _isToggledColor = _checkIfToggledColor(_selectionStyle.attributes);
    _isToggledBackground =
        _checkIfToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor &&
        _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhiteBackground = _isToggledBackground &&
        _selectionStyle.attributes['background']!.value == '#ffffff';
  }

  bool _checkIfToggledColor(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.color.key);
  }

  bool _checkIfToggledBackground(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.background.key);
  }

  void _applyColor(Color color) {
    var hex = color.value.toRadixString(16);
    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }
    hex = '#$hex';
    widget.controller.formatSelection(
        widget.isBackground ? BackgroundAttribute(hex) : ColorAttribute(hex));
    Navigator.of(context).pop();
  }

  void _showColorPicker() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Select Color'),
            backgroundColor: Theme.of(context).canvasColor,
            content: SingleChildScrollView(
              child: MaterialPicker(
                pickerColor: const Color(0x00000000),
                onColorChanged: _applyColor,
                enableLabel: true,
              ),
            ),
          );
        });
  }
}

// Clear Format

class ClearFormatButton extends StatefulWidget {
  const ClearFormatButton({
    required this.icon,
    required this.controller,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final EditorController controller;

  @override
  _ClearFormatButtonState createState() => _ClearFormatButtonState();
}

class _ClearFormatButtonState extends State<ClearFormatButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final fillColor = theme.canvasColor;
    return ToolbarIconButton(
      size: kToolbarButtonHeight,
      fillColor: fillColor,
      hoverElevation: 0,
      highlightElevation: 0,
      icon: Icon(widget.icon, size: kToolbarIconHeight, color: iconColor),
      onPressed: () {
        widget.controller.getSelectionStyle().values.forEach((style) {
          widget.controller.formatSelection(Attribute.clone(style, null));
        });
      },
    );
  }
}

// Indent

class IndentButton extends StatefulWidget {
  const IndentButton({
    required this.icon,
    required this.controller,
    required this.isIncrease,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final EditorController controller;
  final bool isIncrease;

  @override
  _IndentButtonState createState() => _IndentButtonState();
}

class _IndentButtonState extends State<IndentButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final fillColor = theme.canvasColor;
    return ToolbarIconButton(
      size: kToolbarButtonHeight,
      fillColor: fillColor,
      hoverElevation: 0,
      highlightElevation: 0,
      icon: Icon(widget.icon, size: kToolbarIconHeight, color: iconColor),
      onPressed: () {
        final indent = widget.controller
            .getSelectionStyle()
            .attributes[Attribute.indent.key];
        if (indent == null) {
          if (widget.isIncrease) {
            widget.controller.formatSelection(Attribute.indentL1);
          }
          return;
        }
        if (indent.value == 1 && !widget.isIncrease) {
          widget.controller
              .formatSelection(Attribute.clone(Attribute.indentL1, null));
          return;
        }

        if (widget.isIncrease) {
          // Next indent value
          widget.controller
              .formatSelection(Attribute.getIndentLevel(indent.value + 1));
          return;
        }
        // Prev indent value
        widget.controller
            .formatSelection(Attribute.getIndentLevel(indent.value - 1));
      },
    );
  }
}

// Link

class LinkStyleButton extends StatefulWidget {
  const LinkStyleButton({
    required this.controller,
    required this.icon,
    Key? key,
  }) : super(key: key);

  final IconData? icon;
  final EditorController controller;

  @override
  _LinkStyleButtonState createState() => _LinkStyleButtonState();
}

class _LinkStyleButtonState extends State<LinkStyleButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddLink = !widget.controller.selection.isCollapsed;
    return ToolbarIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: kToolbarButtonHeight,
      icon: Icon(
        widget.icon,
        size: kToolbarIconHeight,
        color: canAddLink ? theme.iconTheme.color : theme.disabledColor,
      ),
      fillColor: theme.canvasColor,
      onPressed: canAddLink ? () => _openLinkDialog(context) : null,
    );
  }

  void _openLinkDialog(BuildContext context) {
    showDialog<String>(
        context: context,
        builder: (context) {
          return const LinkEditDialog();
        }).then(_applyLinkAttribute);
  }

  void _applyLinkAttribute(String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    widget.controller.formatSelection(LinkAttribute(value));
  }
}

class LinkEditDialog extends StatefulWidget {
  const LinkEditDialog({Key? key}) : super(key: key);

  @override
  _LinkEditDialogState createState() => _LinkEditDialogState();
}

class _LinkEditDialogState extends State<LinkEditDialog> {
  String _value = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(
        decoration: const InputDecoration(labelText: 'Input Link'),
        autofocus: true,
        onChanged: _handleLinkChanged,
      ),
      actions: [
        TextButton(
          onPressed: _value.isNotEmpty ? _handleFinishEditing : null,
          child: const Text('Finish'),
        ),
      ],
    );
  }

  void _handleLinkChanged(String value) {
    setState(() => _value = value);
  }

  void _handleFinishEditing() {
    Navigator.pop(context, _value);
  }
}

// Embed

class AddEmbedButton extends StatelessWidget {
  const AddEmbedButton({
    required this.controller,
    required this.icon,
    this.fillColor,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final EditorController controller;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolbarIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: kToolbarButtonHeight,
      icon: Icon(icon, size: kToolbarIconHeight, color: theme.iconTheme.color),
      fillColor: fillColor ?? theme.canvasColor,
      onPressed: () {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;
        controller.replaceText(
          index,
          length,
          BlockEmbed.horizontalRule,
          null,
        );
      },
    );
  }
}
