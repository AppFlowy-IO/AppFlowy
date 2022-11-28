import 'package:app_flowy/plugins/document/document.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tuple/tuple.dart';

class FontSizeSwitcher extends StatefulWidget {
  const FontSizeSwitcher({
    super.key,
  });

  @override
  State<FontSizeSwitcher> createState() => _FontSizeSwitcherState();
}

class _FontSizeSwitcherState extends State<FontSizeSwitcher> {
  final _selectedFontSizes = [false, true, false];
  final List<Tuple2<String, double>> _fontSizes = [
    Tuple2(LocaleKeys.moreAction_small.tr(), 12.0),
    Tuple2(LocaleKeys.moreAction_medium.tr(), 14.0),
    Tuple2(LocaleKeys.moreAction_large.tr(), 18.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.semibold(
          LocaleKeys.moreAction_fontSize.tr(),
          fontSize: 12,
        ),
        const SizedBox(
          height: 5,
        ),
        ToggleButtons(
          isSelected: _selectedFontSizes,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _selectedFontSizes.length; i++) {
                _selectedFontSizes[i] = i == index;
              }
              context.read<DocumentStyle>().fontSize = _fontSizes[index].item2;
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          selectedBorderColor: Theme.of(context).colorScheme.primaryContainer,
          selectedColor: Theme.of(context).colorScheme.onSurface,
          fillColor: Theme.of(context).colorScheme.primaryContainer,
          color: Theme.of(context).hintColor,
          constraints: const BoxConstraints(
            minHeight: 40.0,
            minWidth: 80.0,
          ),
          children: const [
            Text(
              'small',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'medium',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'large',
              style: TextStyle(fontSize: 18),
            )
          ],
        )
      ],
    );
  }
}
