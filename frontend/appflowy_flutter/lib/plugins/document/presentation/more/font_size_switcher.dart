import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _DocumentFontSize {
  const _DocumentFontSize(this.name, this.size);
  final String name;
  final double size;
}

class FontSizeSwitcher extends StatefulWidget {
  const FontSizeSwitcher({
    super.key,
  });

  @override
  State<FontSizeSwitcher> createState() => _FontSizeSwitcherState();
}

class _FontSizeSwitcherState extends State<FontSizeSwitcher> {
  final List<_DocumentFontSize> _fontSizes = [
    _DocumentFontSize(LocaleKeys.moreAction_small.tr(), 14.0),
    _DocumentFontSize(LocaleKeys.moreAction_medium.tr(), 18.0),
    _DocumentFontSize(LocaleKeys.moreAction_large.tr(), 22.0),
  ];

  _DocumentFontSize? _selection;

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = AFThemeExtension.of(context).toggleButtonBGColor;
    final foregroundColor = Theme.of(context).colorScheme.onBackground;
    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (context, state) {
        _selection = _fontSizes.firstWhereOrNull(
          (element) => element.size == state.fontSize,
        );
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
            SegmentedButton<_DocumentFontSize>(
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
                    (fontSize) => ButtonSegment(
                      value: fontSize,
                      label: FlowyText(
                        fontSize.name,
                        fontSize: fontSize.size,
                      ),
                    ),
                  )
                  .toList(),
              selected: {
                _selection ?? _fontSizes.first,
              },
              onSelectionChanged: (Set<_DocumentFontSize> newSelection) {
                _selection = newSelection.firstOrNull;
                _updateSelectedFontSize(newSelection.first.size);
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
