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
    this.textFieldHintText,
    this.onTextChanged,
    this.onTextSubmitted,
  });

  factory FlowyOptionTile.text({
    required String text,
    Color? textColor,
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.text,
      text: text,
      textColor: textColor,
      controller: null,
      onTap: onTap,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: trailing,
    );
  }

  factory FlowyOptionTile.textField({
    required TextEditingController controller,
    void Function(String value)? onTextChanged,
    void Function(String value)? onTextSubmitted,
    EdgeInsets textFieldPadding = const EdgeInsets.symmetric(
      horizontal: 0.0,
      vertical: 16.0,
    ),
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
    Widget? trailing,
    String? textFieldHintText,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.textField,
      controller: controller,
      textFieldPadding: textFieldPadding,
      text: null,
      onTap: null,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: trailing,
      textFieldHintText: textFieldHintText,
      onTextChanged: onTextChanged,
      onTextSubmitted: onTextSubmitted,
    );
  }

  factory FlowyOptionTile.checkbox({
    required String text,
    required bool isSelected,
    required VoidCallback? onTap,
    Widget? leftIcon,
    bool showTopBorder = true,
    bool showBottomBorder = true,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.checkbox,
      isSelected: isSelected,
      text: text,
      onTap: onTap,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leading: leftIcon,
      trailing: isSelected
          ? const FlowySvg(
              FlowySvgs.blue_check_s,
              size: Size.square(24.0),
              blendMode: null,
            )
          : null,
    );
  }

  factory FlowyOptionTile.toggle({
    required String text,
    required bool isSelected,
    required void Function(bool value) onValueChanged,
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
  }) {
    return FlowyOptionTile._(
      type: FlowyOptionTileType.toggle,
      text: text,
      controller: null,
      onTap: () => onValueChanged(!isSelected),
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

  // only used in checkbox or switcher
  final bool isSelected;

  // only used in textfield
  final String? textFieldHintText;
  final void Function(String value)? onTextChanged;
  final void Function(String value)? onTextSubmitted;

  final FlowyOptionTileType type;

  @override
  Widget build(BuildContext context) {
    final leadingWidget = _buildLeading();

    final child = ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: FlowyOptionDecorateBox(
        showTopBorder: showTopBorder,
        showBottomBorder: showBottomBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingWidget != null) leadingWidget,
              _buildText(),
              _buildTextField(),
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
      horizontal: leading == null ? 0.0 : 8.0,
      vertical: 16.0,
    );

    return Expanded(
      child: Padding(
        padding: padding,
        child: FlowyText(
          text!,
          fontSize: 15,
          color: textColor,
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
