import 'dart:collection';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textfield_tags/textfield_tags.dart';

extension SelectOptionColorExtension on SelectOptionColor {
  Color make(BuildContext context) {
    final theme = context.watch<AppTheme>();
    switch (this) {
      case SelectOptionColor.Purple:
        return theme.tint1;
      case SelectOptionColor.Pink:
        return theme.tint2;
      case SelectOptionColor.LightPink:
        return theme.tint3;
      case SelectOptionColor.Orange:
        return theme.tint4;
      case SelectOptionColor.Yellow:
        return theme.tint5;
      case SelectOptionColor.Lime:
        return theme.tint6;
      case SelectOptionColor.Green:
        return theme.tint7;
      case SelectOptionColor.Aqua:
        return theme.tint8;
      case SelectOptionColor.Blue:
        return theme.tint9;
      default:
        throw ArgumentError;
    }
  }

  String optionName() {
    switch (this) {
      case SelectOptionColor.Purple:
        return LocaleKeys.grid_selectOption_purpleColor.tr();
      case SelectOptionColor.Pink:
        return LocaleKeys.grid_selectOption_pinkColor.tr();
      case SelectOptionColor.LightPink:
        return LocaleKeys.grid_selectOption_lightPinkColor.tr();
      case SelectOptionColor.Orange:
        return LocaleKeys.grid_selectOption_orangeColor.tr();
      case SelectOptionColor.Yellow:
        return LocaleKeys.grid_selectOption_yellowColor.tr();
      case SelectOptionColor.Lime:
        return LocaleKeys.grid_selectOption_limeColor.tr();
      case SelectOptionColor.Green:
        return LocaleKeys.grid_selectOption_greenColor.tr();
      case SelectOptionColor.Aqua:
        return LocaleKeys.grid_selectOption_aquaColor.tr();
      case SelectOptionColor.Blue:
        return LocaleKeys.grid_selectOption_blueColor.tr();
      default:
        throw ArgumentError;
    }
  }
}

class SelectOptionTextField extends StatelessWidget {
  final FocusNode _focusNode;
  final TextEditingController _controller;
  final TextfieldTagsController tagController;
  final LinkedHashMap<String, SelectOption> optionMap;
  final double distanceToText;

  final Function(String) onNewTag;

  SelectOptionTextField({
    required this.optionMap,
    required this.distanceToText,
    required this.tagController,
    required this.onNewTag,
    TextEditingController? controller,
    FocusNode? focusNode,
    Key? key,
  })  : _controller = controller ?? TextEditingController(),
        _focusNode = focusNode ?? FocusNode(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return TextFieldTags(
      textEditingController: _controller,
      textfieldTagsController: tagController,
      initialTags: optionMap.keys.toList(),
      focusNode: _focusNode,
      textSeparators: const [' ', ','],
      inputfieldBuilder: (BuildContext context, editController, focusNode, error, onChanged, onSubmitted) {
        return ((context, sc, tags, onTagDelegate) {
          tags.retainWhere((name) => optionMap.containsKey(name) == false);
          if (tags.isNotEmpty) {
            assert(tags.length == 1);
            onNewTag(tags.first);
          }

          return TextField(
            controller: editController,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: theme.shader3, width: 1.0),
                borderRadius: Corners.s10Border,
              ),
              isDense: true,
              prefixIcon: _renderTags(sc),
              hintText: LocaleKeys.grid_selectOption_searchOption.tr(),
              prefixIconConstraints: BoxConstraints(maxWidth: distanceToText),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.main1,
                  width: 1.0,
                ),
                borderRadius: Corners.s10Border,
              ),
            ),
          );
        });
      },
    );
  }

  Widget? _renderTags(ScrollController sc) {
    if (optionMap.isEmpty) {
      return null;
    }

    final children = optionMap.values.map((option) => SelectOptionTag(option: option)).toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        controller: sc,
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      ),
    );
  }
}

class SelectOptionTag extends StatelessWidget {
  final SelectOption option;
  const SelectOptionTag({required this.option, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: option.color.make(context),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(child: FlowyText.medium(option.name, fontSize: 12)),
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
    );
  }
}
