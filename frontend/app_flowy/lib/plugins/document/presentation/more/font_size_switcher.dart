import 'package:app_flowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:easy_localization/easy_localization.dart';

class FontSizeSwitcher extends StatefulWidget {
  const FontSizeSwitcher({
    super.key,
  });

  @override
  State<FontSizeSwitcher> createState() => _FontSizeSwitcherState();
}

class _FontSizeSwitcherState extends State<FontSizeSwitcher> {
  final List<bool> _selectedFontSizes = [false, true, false];
  final List<Tuple2<String, double>> _fontSizes = [
    Tuple2(LocaleKeys.moreAction_small.tr(), 12.0),
    Tuple2(LocaleKeys.moreAction_medium.tr(), 14.0),
    Tuple2(LocaleKeys.moreAction_large.tr(), 18.0),
  ];

  @override
  void initState() {
    super.initState();

    final fontSize =
        context.read<DocumentAppearanceCubit>().documentAppearance.fontSize;
    final index = _fontSizes.indexWhere((element) => element.item2 == fontSize);
    _updateSelectedFontSize(index);
  }

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
            _updateSelectedFontSize(index);
            _sync(index);
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
          children: _fontSizes
              .map((e) => Text(
                    e.item1,
                    style: TextStyle(fontSize: e.item2),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _updateSelectedFontSize(int index) {
    setState(() {
      for (int i = 0; i < _selectedFontSizes.length; i++) {
        _selectedFontSizes[i] = i == index;
      }
    });
  }

  void _sync(int index) {
    if (index < 0 || index >= _fontSizes.length) return;
    final fontSize = _fontSizes[index].item2;
    final cubit = context.read<DocumentAppearanceCubit>();
    final documentAppearance = cubit.documentAppearance;
    cubit.sync(documentAppearance.copyWith(fontSize: fontSize));
  }
}
