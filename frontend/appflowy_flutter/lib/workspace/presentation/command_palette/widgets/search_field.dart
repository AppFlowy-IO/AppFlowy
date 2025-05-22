import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, this.query, this.isLoading = false});

  final String? query;
  final bool isLoading;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final FocusNode focusNode;
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.query);
    focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    focusNode.requestFocus();
    // Update the text selection after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (node.hasFocus &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      node.nextFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  Widget _buildSuffixIcon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 12),
      child: FlowyTooltip(
        message: LocaleKeys.commandPalette_clearSearchTooltip.tr(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _clearSearch,
            child: SizedBox.square(
              dimension: 28,
              child: Center(
                child: FlowySvg(
                  FlowySvgs.search_clear_m,
                  color: AppFlowyTheme.of(context).iconColorScheme.secondary,
                  size: const Size.square(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final radius = BorderRadius.circular(theme.spacing.l);

    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.trim().isNotEmpty;
          return FlowyTextField(
            focusNode: focusNode,
            controller: controller,
            textStyle: theme.textStyle.heading4
                .standard(color: theme.textColorScheme.primary),
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.borderColorScheme.primary),
                borderRadius: radius,
              ),
              isDense: false,
              hintText: LocaleKeys.search_searchOrAskAI.tr(),
              hintStyle: theme.textStyle.heading4
                  .standard(color: theme.textColorScheme.tertiary),
              counterText: "",
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide:
                    BorderSide(color: theme.borderColorScheme.themeThick),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: FlowySvg(
                  FlowySvgs.search_icon_m,
                  color: theme.iconColorScheme.secondary,
                  size: Size.square(20),
                ),
              ),
              prefixIconConstraints: BoxConstraints.loose(Size(40, 20)),
              suffixIconConstraints:
                  hasText ? BoxConstraints.loose(Size(48, 28)) : null,
              suffixIcon: hasText ? _buildSuffixIcon(context) : null,
            ),
            onChanged: (value) => context
                .read<CommandPaletteBloc>()
                .add(CommandPaletteEvent.searchChanged(search: value)),
          );
        },
      ),
    );
  }

  void _clearSearch() {
    controller.clear();
    context
        .read<CommandPaletteBloc>()
        .add(const CommandPaletteEvent.clearSearch());
    focusNode.requestFocus();
  }
}
