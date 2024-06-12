import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
  late final controller = TextEditingController(text: widget.query);

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (node.hasFocus &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          node.nextFocus();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
    focusNode.requestFocus();
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HSpace(12),
        FlowySvg(
          FlowySvgs.search_m,
          color: Theme.of(context).hintColor,
        ),
        Expanded(
          child: FlowyTextField(
            focusNode: focusNode,
            controller: controller,
            textStyle:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
            decoration: InputDecoration(
              constraints: const BoxConstraints(maxHeight: 48),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: Corners.s8Border,
              ),
              isDense: false,
              hintText: LocaleKeys.commandPalette_placeholder.tr(),
              hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
              errorStyle: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).colorScheme.error),
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: controller.text.trim().isNotEmpty ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Builder(
                      builder: (context) {
                        final icon = Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AFThemeExtension.of(context).lightGreyHover,
                          ),
                          child: const FlowySvg(
                            FlowySvgs.close_s,
                            blendMode: BlendMode.dst,
                            size: Size.square(16),
                          ),
                        );
                        if (controller.text.isEmpty) {
                          return icon;
                        }

                        return FlowyTooltip(
                          message:
                              LocaleKeys.commandPalette_clearSearchTooltip.tr(),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: controller.text.trim().isNotEmpty
                                  ? () {
                                      controller.clear();
                                      context.read<CommandPaletteBloc>().add(
                                            const CommandPaletteEvent
                                                .searchChanged(
                                              search: "",
                                            ),
                                          );
                                    }
                                  : null,
                              child: icon,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const HSpace(8),
                  // TODO(Mathias): Remove beta when support database search
                  FlowyTooltip(
                    message: LocaleKeys.commandPalette_betaTooltip.tr(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AFThemeExtension.of(context).lightGreyHover,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FlowyText.semibold(
                        LocaleKeys.commandPalette_betaLabel.tr(),
                        fontSize: 11,
                        lineHeight: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              counterText: "",
              focusedBorder: const OutlineInputBorder(
                borderRadius: Corners.s8Border,
                borderSide: BorderSide(color: Colors.transparent),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: Corners.s8Border,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            onChanged: (value) => context
                .read<CommandPaletteBloc>()
                .add(CommandPaletteEvent.searchChanged(search: value)),
          ),
        ),
        if (widget.isLoading) ...[
          FlowyTooltip(
            message: LocaleKeys.commandPalette_loadingTooltip.tr(),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          const HSpace(12),
        ],
      ],
    );
  }
}
