import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/util/google_font_family_extension.dart';
import 'package:appflowy/util/levenshtein.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_list_tile.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_value_dropdown.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

final customizeFontToolbarItem = ToolbarItem(
  id: 'editor.font',
  group: 4,
  isActive: onlyShowInTextType,
  builder: (context, editorState, highlightColor, _) {
    final selection = editorState.selection!;
    final popoverController = PopoverController();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: FontFamilyDropDown(
        currentFontFamily: '',
        offset: const Offset(0, 12),
        popoverController: popoverController,
        onOpen: () => keepEditorFocusNotifier.increase(),
        onClose: () => keepEditorFocusNotifier.decrease(),
        showResetButton: true,
        onFontFamilyChanged: (fontFamily) async {
          popoverController.close();
          try {
            await editorState.formatDelta(selection, {
              AppFlowyRichTextKeys.fontFamily: fontFamily,
            });
          } catch (e) {
            Log.error('Failed to set font family: $e');
          }
        },
        onResetFont: () async => editorState.formatDelta(selection, {
          AppFlowyRichTextKeys.fontFamily: null,
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: FlowyTooltip(
            message: LocaleKeys.document_plugins_fonts.tr(),
            child: const FlowySvg(
              FlowySvgs.font_family_s,
              size: Size.square(16.0),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  },
);

class ThemeFontFamilySetting extends StatefulWidget {
  const ThemeFontFamilySetting({
    super.key,
    required this.currentFontFamily,
  });

  final String currentFontFamily;
  static Key textFieldKey = const Key('FontFamilyTextField');
  static Key resetButtonkey = const Key('FontFamilyResetButton');
  static Key popoverKey = const Key('FontFamilyPopover');

  @override
  State<ThemeFontFamilySetting> createState() => _ThemeFontFamilySettingState();
}

class _ThemeFontFamilySettingState extends State<ThemeFontFamilySetting> {
  @override
  Widget build(BuildContext context) {
    return SettingListTile(
      label: LocaleKeys.settings_appearance_fontFamily_label.tr(),
      resetButtonKey: ThemeFontFamilySetting.resetButtonkey,
      onResetRequested: () {
        context.read<AppearanceSettingsCubit>().resetFontFamily();
        context
            .read<DocumentAppearanceCubit>()
            .syncFontFamily(DefaultAppearanceSettings.kDefaultFontFamily);
      },
      trailing: [
        FontFamilyDropDown(
          currentFontFamily: widget.currentFontFamily,
        ),
      ],
    );
  }
}

class FontFamilyDropDown extends StatefulWidget {
  const FontFamilyDropDown({
    super.key,
    required this.currentFontFamily,
    this.onOpen,
    this.onClose,
    this.onFontFamilyChanged,
    this.child,
    this.popoverController,
    this.offset,
    this.showResetButton = false,
    this.onResetFont,
  });

  final String currentFontFamily;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final void Function(String fontFamily)? onFontFamilyChanged;
  final Widget? child;
  final PopoverController? popoverController;
  final Offset? offset;
  final bool showResetButton;
  final VoidCallback? onResetFont;

  @override
  State<FontFamilyDropDown> createState() => _FontFamilyDropDownState();
}

class _FontFamilyDropDownState extends State<FontFamilyDropDown> {
  final List<String> availableFonts = GoogleFonts.asMap().keys.toList();
  final ValueNotifier<String> query = ValueNotifier('');

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingValueDropDown(
      popoverKey: ThemeFontFamilySetting.popoverKey,
      popoverController: widget.popoverController,
      currentValue: widget.currentFontFamily.parseFontFamilyName(),
      onClose: () {
        query.value = '';
        widget.onClose?.call();
      },
      offset: widget.offset,
      child: widget.child,
      popupBuilder: (_) {
        widget.onOpen?.call();
        return CustomScrollView(
          shrinkWrap: true,
          slivers: [
            if (widget.showResetButton)
              SliverPersistentHeader(
                delegate: _ResetFontButton(
                  onPressed: widget.onResetFont,
                ),
                pinned: true,
              ),
            SliverPadding(
              padding: const EdgeInsets.only(right: 8),
              sliver: SliverToBoxAdapter(
                child: FlowyTextField(
                  key: ThemeFontFamilySetting.textFieldKey,
                  hintText:
                      LocaleKeys.settings_appearance_fontFamily_search.tr(),
                  autoFocus: false,
                  debounceDuration: const Duration(milliseconds: 300),
                  onChanged: (value) {
                    query.value = value;
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 4),
            ),
            ValueListenableBuilder(
              valueListenable: query,
              builder: (context, value, child) {
                var displayed = availableFonts;
                if (value.isNotEmpty) {
                  displayed = availableFonts
                      .where(
                        (font) => font
                            .toLowerCase()
                            .contains(value.toLowerCase().toString()),
                      )
                      .sorted((a, b) => levenshtein(a, b))
                      .toList();
                }
                return SliverFixedExtentList.builder(
                  itemBuilder: (context, index) => _fontFamilyItemButton(
                    context,
                    GoogleFonts.getFont(displayed[index]),
                  ),
                  itemCount: displayed.length,
                  itemExtent: 32,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _fontFamilyItemButton(
    BuildContext context,
    TextStyle style,
  ) {
    final buttonFontFamily = style.fontFamily!.parseFontFamilyName();

    return Tooltip(
      message: buttonFontFamily,
      waitDuration: const Duration(milliseconds: 150),
      child: SizedBox(
        key: ValueKey(buttonFontFamily),
        height: 32,
        child: FlowyButton(
          onHover: (_) => FocusScope.of(context).unfocus(),
          text: FlowyText.medium(
            buttonFontFamily,
            fontFamily: style.fontFamily!,
          ),
          rightIcon:
              buttonFontFamily == widget.currentFontFamily.parseFontFamilyName()
                  ? const FlowySvg(FlowySvgs.check_s)
                  : null,
          onTap: () {
            if (widget.onFontFamilyChanged != null) {
              widget.onFontFamilyChanged!(buttonFontFamily);
            } else {
              final fontFamily = style.fontFamily!.parseFontFamilyName();
              if (widget.currentFontFamily.parseFontFamilyName() !=
                  buttonFontFamily) {
                context
                    .read<AppearanceSettingsCubit>()
                    .setFontFamily(fontFamily);
                context
                    .read<DocumentAppearanceCubit>()
                    .syncFontFamily(fontFamily);
              }
            }
            PopoverContainer.of(context).close();
          },
        ),
      ),
    );
  }
}

class _ResetFontButton extends SliverPersistentHeaderDelegate {
  _ResetFontButton({
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8.0),
      child: FlowyTextButton(
        LocaleKeys.document_toolbar_resetToDefaultFont.tr(),
        onPressed: onPressed,
      ),
    );
  }

  @override
  double get maxExtent => 35;

  @override
  double get minExtent => 35;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
