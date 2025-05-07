import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
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
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        if (!hasText) return const SizedBox.shrink();
        return FlowyTooltip(
          message: LocaleKeys.commandPalette_clearSearchTooltip.tr(),
          child: AFGhostButton.normal(
            onTap: _clearSearch,
            padding: EdgeInsets.zero,
            builder: (context, isHovering, disabled) => SizedBox.square(
              dimension: 28,
              child: Center(
                child: FlowySvg(
                  FlowySvgs.search_clear_m,
                  color: AppFlowyTheme.of(context).iconColorScheme.tertiary,
                  size: const Size.square(20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FlowySvg(
            FlowySvgs.search_icon_m,
            color: theme.iconColorScheme.secondary,
            size: Size.square(20),
          ),
          HSpace(8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: FlowyTextField(
                focusNode: focusNode,
                controller: controller,
                textStyle: theme.textStyle.heading4
                    .standard(color: theme.textColorScheme.primary),
                decoration: InputDecoration(
                  constraints: const BoxConstraints(maxHeight: 48),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                    borderRadius: Corners.s8Border,
                  ),
                  isDense: false,
                  hintText: LocaleKeys.search_searchOrAskAI.tr(),
                  hintStyle: theme.textStyle.heading4
                      .standard(color: theme.textColorScheme.tertiary),
                  counterText: "",
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: Corners.s8Border,
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
                onChanged: (value) => context
                    .read<CommandPaletteBloc>()
                    .add(CommandPaletteEvent.searchChanged(search: value)),
              ),
            ),
          ),
          _buildSuffixIcon(context),
        ],
      ),
    );
  }

  void _clearSearch() {
    controller.clear();
    context
        .read<CommandPaletteBloc>()
        .add(const CommandPaletteEvent.clearSearch());
  }
}
