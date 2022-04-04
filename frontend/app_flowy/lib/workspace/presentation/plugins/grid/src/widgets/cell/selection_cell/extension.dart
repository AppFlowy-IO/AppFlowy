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
  final TextEditingController _controller;
  final FocusNode _focusNode;

  SelectOptionTextField({
    TextEditingController? controller,
    FocusNode? focusNode,
    Key? key,
  })  : _controller = controller ?? TextEditingController(),
        _focusNode = focusNode ?? FocusNode(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldTags(
      textEditingController: _controller,
      initialTags: ["abc", "bdf"],
      focusNode: _focusNode,
      textSeparators: const [' ', ','],
      inputfieldBuilder: (
        BuildContext context,
        TextEditingController editController,
        FocusNode focusNode,
        String? error,
        void Function(String)? onChanged,
        void Function(String)? onSubmitted,
      ) {
        return ((context, sc, tags, onTagDelegate) {
          return TextField(
            controller: editController,
            focusNode: focusNode,
            onChanged: (value) {},
            onEditingComplete: () => focusNode.unfocus(),
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              isDense: true,
              prefixIcon: _renderTags(tags, sc),
            ),
          );
        });
      },
    );
  }

  Widget? _renderTags(List<String> tags, ScrollController sc) {
    if (tags.isEmpty) {
      return null;
    }

    return SingleChildScrollView(
      controller: sc,
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 74, 137, 92),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: FlowyText.medium("efc", fontSize: 12),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 74, 137, 92),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: FlowyText.medium("abc", fontSize: 12),
        )
      ]),
    );
  }
}

class SelectionBadge extends StatelessWidget {
  final SelectOption option;
  const SelectionBadge({required this.option, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: option.color.make(context),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: FlowyText.medium(option.name, fontSize: 12),
    );
  }
}
