import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchField extends StatelessWidget {
  const SearchField({super.key, this.isLoading = false});

  final bool isLoading;

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
            controller: TextEditingController(),
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
              hintText: 'Type to search...',
              hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
              errorStyle: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).colorScheme.error),
              suffixText: "",
              counterText: "",
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: Corners.s8Border,
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
                borderRadius: Corners.s8Border,
              ),
            ),
            onChanged: (value) => context
                .read<CommandPaletteBloc>()
                .add(CommandPaletteEvent.searchChanged(search: value)),
          ),
        ),
        if (isLoading) ...[
          const HSpace(12),
          const FlowyTooltip(
            message: 'We are looking for results...',
            child: SizedBox(
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
