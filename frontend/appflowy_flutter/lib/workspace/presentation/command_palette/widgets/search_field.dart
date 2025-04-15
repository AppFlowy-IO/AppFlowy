import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
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
        final clearIcon = Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AFThemeExtension.of(context).lightGreyHover,
          ),
          child: const FlowySvg(
            FlowySvgs.close_s,
            size: Size.square(16),
          ),
        );
        return AnimatedOpacity(
          opacity: hasText ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: hasText
              ? FlowyTooltip(
                  message: LocaleKeys.commandPalette_clearSearchTooltip.tr(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _clearSearch,
                      child: clearIcon,
                    ),
                  ),
                )
              : clearIcon,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cache theme and text styles
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 14);
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 14,
      color: theme.hintColor,
    );

    // Choose the leading icon based on loading state
    final Widget leadingIcon = widget.isLoading
        ? FlowyTooltip(
            message: LocaleKeys.commandPalette_loadingTooltip.tr(),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          )
        : SizedBox(
            width: 20,
            height: 20,
            child: FlowySvg(
              FlowySvgs.search_m,
              color: theme.hintColor,
            ),
          );

    return Row(
      children: [
        const HSpace(12),
        leadingIcon,
        Expanded(
          child: FlowyTextField(
            focusNode: focusNode,
            controller: controller,
            textStyle: textStyle,
            decoration: InputDecoration(
              constraints: const BoxConstraints(maxHeight: 48),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: Corners.s8Border,
              ),
              isDense: false,
              hintText: LocaleKeys.commandPalette_placeholder.tr(),
              hintStyle: hintStyle,
              errorStyle: theme.textTheme.bodySmall!
                  .copyWith(color: theme.colorScheme.error),
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSuffixIcon(context),
                  const HSpace(8),
                ],
              ),
              counterText: "",
              focusedBorder: const OutlineInputBorder(
                borderRadius: Corners.s8Border,
                borderSide: BorderSide(color: Colors.transparent),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: Corners.s8Border,
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
            ),
            onChanged: (value) => context
                .read<CommandPaletteBloc>()
                .add(CommandPaletteEvent.searchChanged(search: value)),
          ),
        ),
      ],
    );
  }

  void _clearSearch() {
    controller.clear();
    context
        .read<CommandPaletteBloc>()
        .add(const CommandPaletteEvent.clearSearch());
  }
}
