import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class FontSizeSwitcher extends StatefulWidget {
  const FontSizeSwitcher({
    super.key,
  });

  @override
  State<FontSizeSwitcher> createState() => _FontSizeSwitcherState();
}

class _FontSizeSwitcherState extends State<FontSizeSwitcher> {
  final List<(String, double, bool)> _fontSizes = [
    (LocaleKeys.moreAction_small.tr(), 14.0, false),
    (LocaleKeys.moreAction_medium.tr(), 18.0, true),
    (LocaleKeys.moreAction_large.tr(), 22.0, false),
  ];
  Set<(String, double, bool)> _selection = <(String, double, bool)>{};

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = AFThemeExtension.of(context).toggleButtonBGColor;
    final foregroundColor = Theme.of(context).colorScheme.onBackground;
    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (context, state) {
        _selection = _fontSizes
            .map((e) => e.$2 == state.fontSize ? e : null)
            .toSet()
            .whereNotNull()
            .toSet();
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
            SegmentedButton<(String, double, bool)>(
              showSelectedIcon: false,
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
                shadowColor: selectedBgColor.withOpacity(0.3),
                padding: const EdgeInsets.all(16),
                side: BorderSide(
                  width: 0.5,
                  color: foregroundColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              segments: _fontSizes
                  .map(
                    (e) => ButtonSegment(
                      value: e,
                      label: Text(
                        e.$1,
                        style: TextStyle(fontSize: e.$2),
                      ),
                    ),
                  )
                  .toList(),
              selected: _selection,
              onSelectionChanged: (Set<(String, double, bool)> newSelection) {
                _selection = newSelection;
                _updateSelectedFontSize(newSelection.first.$2);
              },
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
