import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final List<Tuple3<String, double, bool>> _fontSizes = [
    Tuple3(LocaleKeys.moreAction_small.tr(), 12.0, false),
    Tuple3(LocaleKeys.moreAction_medium.tr(), 14.0, true),
    Tuple3(LocaleKeys.moreAction_large.tr(), 18.0, false),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = AFThemeExtension.of(context).toggleButtonBGColor;
    final foregroundColor = Theme.of(context).colorScheme.onBackground;
    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText.semibold(
              LocaleKeys.moreAction_fontSize.tr(),
              fontSize: 12,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(
              height: 5,
            ),
            ToggleButtons(
              isSelected:
                  _fontSizes.map((e) => e.item2 == state.fontSize).toList(),
              onPressed: (int index) {
                _updateSelectedFontSize(_fontSizes[index].item2);
              },
              color: foregroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              borderColor: foregroundColor,
              borderWidth: 0.5,
              // when selected
              selectedColor: foregroundColor,
              selectedBorderColor: foregroundColor,
              fillColor: selectedBgColor,
              // when hover
              hoverColor: selectedBgColor.withOpacity(0.3),
              constraints: const BoxConstraints(
                minHeight: 40.0,
                minWidth: 80.0,
              ),
              children: _fontSizes
                  .map(
                    (e) => Text(
                      e.item1,
                      style: TextStyle(fontSize: e.item2),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  void _updateSelectedFontSize(double fontSize) {
    context.read<DocumentAppearanceCubit>().syncFontSize(fontSize);
  }
}
