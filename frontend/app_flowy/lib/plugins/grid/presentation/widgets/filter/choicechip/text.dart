import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'choicechip.dart';

class TextFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const TextFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}

class TextFilterEditor extends StatelessWidget {
  const TextFilterEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [],
          ),
        ),
        FilterTextField(
          hintText: LocaleKeys.grid_settings_filterBy.tr(),
          onChanged: (text) {},
        )
      ],
    );
  }
}
