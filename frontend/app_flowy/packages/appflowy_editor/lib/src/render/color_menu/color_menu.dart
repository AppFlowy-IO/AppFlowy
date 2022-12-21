import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/style/editor_style.dart';
import 'package:flutter/material.dart';

import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/edit_select_option_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';

class ColorMenu extends StatefulWidget {
  const ColorMenu({
    Key? key,
    this.backgroundColor,
    this.fontColor,
    this.editorState,
    required this.onSubmittedbackgroundColor,
    required this.onSubmittedFontColor,
    required this.onFocusChange,
  }) : super(key: key);

  final String? backgroundColor;
  final String? fontColor;
  final EditorState? editorState;
  final void Function(String color) onSubmittedbackgroundColor;
  final void Function(String color) onSubmittedFontColor;

  final void Function(bool value) onFocusChange;

  @override
  State<ColorMenu> createState() => _ColorMenuState();
}

class _ColorMenuState extends State<ColorMenu> {
  final _focusNode = FocusNode();

  EditorStyle? get style => widget.editorState?.editorStyle;

  @override
  void initState() {
    super.initState();

    _focusNode.requestFocus();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        decoration: BoxDecoration(
          color: style?.selectionMenuBackgroundColor ?? Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
              controller: ScrollController(),
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderfontColor(),
                  const SizedBox(height: 10.0),
                  _fontColorSelect(),
                  const SizedBox(height: 10.0),
                  _buildHeaderbackgroundColor(),
                  const SizedBox(height: 10.0),
                  _backgroundColorSelect(),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildHeaderfontColor() {
    return const Text(
      'Font Color',
      style: TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHeaderbackgroundColor() {
    return const Text(
      'Background Color',
      style: TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _backgroundColorIcon({
    required SelectOptionColorPB color,
    required bool isSelected,
  }) {
    Widget? checkmark;

    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    final colorIcon = SizedBox.square(
      dimension: 12,
      child: Container(
        decoration: BoxDecoration(
          color: color.make(context),
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(color.optionName()),
        leftIcon: colorIcon,
        rightIcon: checkmark,
      ),
    );
  }

  Widget _backgroundColorDefaultIcon({
    required Color color,
    required bool isSelected,
  }) {
    Widget? checkmark;

    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    final colorIcon = SizedBox.square(
      dimension: 16,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium('Default'),
        leftIcon: colorIcon,
        rightIcon: checkmark,
      ),
    );
  }

  Widget _backgroundColorSelect() {
    print(widget.backgroundColor);
    print('color.toString()');
    final cells = SelectOptionColorPB.values.map((color) {
      return InkWell(
          onTap: () {
            widget.onSubmittedbackgroundColor(
                '0x${color.make(context).value.toRadixString(16)}');
          },
          child: _backgroundColorIcon(
            color: color,
            isSelected: widget.backgroundColor ==
                '0x${color.make(context).value.toRadixString(16)}',
          ));
    }).toList();
    cells.add(InkWell(
        onTap: () {
          widget.onSubmittedFontColor('0xFFFFFFFF');
        },
        child: _backgroundColorDefaultIcon(
          color: Color(0xFFFFFFFF),
          isSelected: (widget.backgroundColor == null ||
              widget.fontColor == '0xFFFFFFFF'),
        )));
    return Container(
        child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  controller: ScrollController(),
                  separatorBuilder: (context, index) {
                    return VSpace(GridSize.typeOptionSeparatorHeight);
                  },
                  itemCount: cells.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return cells[index];
                  },
                ),
              ],
            )));
  }

  Widget _fontColorSelect() {
    print(widget.fontColor);
    print('color.toString()');
    final cells = SelectOptionColorPB.values.map((color) {
      return InkWell(
          onTap: () {
            print(color.toString());
            print('color.toString()');
            widget.onSubmittedFontColor(
                '0x${color.make(context).value.toRadixString(16)}');
          },
          child: _backgroundColorIcon(
            color: color,
            isSelected: widget.fontColor ==
                '0x${color.make(context).value.toRadixString(16)}',
          ));
    }).toList();
    cells.add(InkWell(
        onTap: () {
          widget.onSubmittedFontColor('0xFF000000');
        },
        child: _backgroundColorDefaultIcon(
          color: Color(0xFF000000),
          isSelected:
              (widget.fontColor == null || widget.fontColor == '0xFF000000'),
        )));
    return Container(
        child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  controller: ScrollController(),
                  separatorBuilder: (context, index) {
                    return VSpace(GridSize.typeOptionSeparatorHeight);
                  },
                  itemCount: cells.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return cells[index];
                  },
                ),
              ],
            )));
  }

  void _onFocusChange() {
    widget.onFocusChange(_focusNode.hasFocus);
  }
}

class TypeOptionSeparator extends StatelessWidget {
  const TypeOptionSeparator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        color: Theme.of(context).dividerColor,
        height: 1.0,
      ),
    );
  }
}
