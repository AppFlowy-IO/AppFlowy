import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum FlowyOptionTileType {
  text,
  textField,
  checkbox,
  toggle,
}

class FlowyOptionTile extends StatelessWidget {
  const FlowyOptionTile._({
    super.key,
    required this.type,
    this.showTopBorder = true,
    this.showBottomBorder = true,
    this.text,
    this.textColor,
    this.controller,
    this.leading,
    this.onTap,
    this.trailing,
    this.textFieldPadding = const EdgeInsets.symmetric(
      horizontal: 12.0,
      vertical: 2.0,
    ),
    this.isSelected = false,
    this.onValueChanged,
    this.textFieldHintText,
    this.onTextChanged,
    this.onTextSubmitted,
    this.autofocus,
    this.content,
    this.backgroundColor,
    this.fontFamily,
    this.height,
  });

  factory FlowyOptionTile.text({
    String? text,
    Widget? content,
    Color? textColor,
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
    Widget? trailing,
    VoidCallback? onTap,
    double? height,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.text,
      text: text,
      content: content,
      textColor: textColor,
      onTap: onTap,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: trailing,
      height: height,
    );
  }

  factory FlowyOptionTile.textField({
    required TextEditingController controller,
    void Function(String value)? onTextChanged,
    void Function(String value)? onTextSubmitted,
    EdgeInsets textFieldPadding = const EdgeInsets.symmetric(
      vertical: 16.0,
    ),
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
    Widget? trailing,
    String? textFieldHintText,
    bool autofocus = false,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.textField,
      controller: controller,
      textFieldPadding: textFieldPadding,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: trailing,
      textFieldHintText: textFieldHintText,
      onTextChanged: onTextChanged,
      onTextSubmitted: onTextSubmitted,
      autofocus: autofocus,
    );
  }

  factory FlowyOptionTile.checkbox({
    Key? key,
    required String text,
    required bool isSelected,
    required VoidCallback? onTap,
    Color? textColor,
    Widget? leftIcon,
    Widget? content,
    bool showTopBorder = true,
    bool showBottomBorder = true,
    String? fontFamily,
    Color? backgroundColor,
  }) {
    return FlowyOptionTile._(
      key: key,
      type: FlowyOptionTileType.checkbox,
      isSelected: isSelected,
      text: text,
      textColor: textColor,
      content: content,
      onTap: onTap,
      fontFamily: fontFamily,
      backgroundColor: backgroundColor,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: isSelected
          ? const FlowySvg(
              FlowySvgs.m_blue_check_s,
              blendMode: null,
            )
          : null,
    );
  }

  factory FlowyOptionTile.toggle({
    required String text,
    required bool isSelected,
    required void Function(bool value) onValueChanged,
    void Function()? onTap,
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.toggle,
      text: text,
      onTap: onTap ?? () => onValueChanged(!isSelected),
      onValueChanged: onValueChanged,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: _Toggle(value: isSelected, onChanged: onValueChanged),
    );
  }

  final bool showTopBorder;
  final bool showBottomBorder;
  final String? text;
  final Color? textColor;
  final TextEditingController? controller;
  final EdgeInsets textFieldPadding;
  final void Function()? onTap;
  final Widget? leading;
  final Widget? trailing;

  // customize the content widget
  final Widget? content;

  // only used in checkbox or switcher
  final bool isSelected;

  // only used in switcher
  final void Function(bool value)? onValueChanged;

  // only used in textfield
  final String? textFieldHintText;
  final void Function(String value)? onTextChanged;
  final void Function(String value)? onTextSubmitted;
  final bool? autofocus;

  final FlowyOptionTileType type;

  final Color? backgroundColor;
  final String? fontFamily;

  final double? height;

  @override
  Widget build(BuildContext context) {
    final leadingWidget = _buildLeading();

    final child = FlowyOptionDecorateBox(
      color: backgroundColor,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              if (leadingWidget != null) leadingWidget,
              if (content != null) content!,
              if (content == null) _buildText(),
              if (content == null) _buildTextField(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );

    if (type == FlowyOptionTileType.checkbox ||
        type == FlowyOptionTileType.toggle ||
        type == FlowyOptionTileType.text) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }

  Widget? _buildLeading() {
    if (leading != null) {
      return Center(child: leading);
    } else {
      return null;
    }
  }

  Widget _buildText() {
    if (text == null || type == FlowyOptionTileType.textField) {
      return const SizedBox.shrink();
    }

    final padding = EdgeInsets.symmetric(
      horizontal: leading == null ? 0.0 : 12.0,
      vertical: 14.0,
    );

    return Expanded(
      child: Padding(
        padding: padding,
        child: FlowyText(
          text!,
          fontSize: 16,
          color: textColor,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Container(
        constraints: const BoxConstraints.tightFor(
          height: 54.0,
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          autofocus: autofocus ?? false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: textFieldPadding,
            hintText: textFieldHintText,
          ),
          onChanged: onTextChanged,
          onSubmitted: onTextSubmitted,
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    // CupertinoSwitch adds a 8px margin all around. The original size of the
    // switch is 38 x 22.
    return SizedBox(
      width: 46,
      height: 30,
      child: FittedBox(
        fit: BoxFit.fill,
        child: CupertinoSwitch(
          value: value,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
