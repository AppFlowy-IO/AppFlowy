import 'package:flutter/material.dart';

import 'package:appflowy/flutter/af_dropdown_menu.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsDropdown<T> extends StatefulWidget {
  const SettingsDropdown({
    super.key,
    required this.selectedOption,
    required this.options,
    this.onChanged,
    this.actions,
    this.expandWidth = true,
  });

  final T selectedOption;
  final List<DropdownMenuEntry<T>> options;
  final void Function(T)? onChanged;
  final List<Widget>? actions;
  final bool expandWidth;

  @override
  State<SettingsDropdown<T>> createState() => _SettingsDropdownState<T>();
}

class _SettingsDropdownState<T> extends State<SettingsDropdown<T>> {
  late final TextEditingController controller = TextEditingController(
    text: widget.selectedOption is String
        ? widget.selectedOption as String
        : widget.options
                .firstWhereOrNull((e) => e.value == widget.selectedOption)
                ?.label ??
            '',
  );

  @override
  Widget build(BuildContext context) {
    final fontFamily = context.read<AppearanceSettingsCubit>().state.font;
    final fontFamilyUsed =
        getGoogleFontSafely(fontFamily).fontFamily ?? defaultFontFamily;

    return Row(
      children: [
        Expanded(
          child: AFDropdownMenu<T>(
            controller: controller,
            expandedInsets: widget.expandWidth ? EdgeInsets.zero : null,
            initialSelection: widget.selectedOption,
            dropdownMenuEntries: widget.options,
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: fontFamilyUsed,
                  fontWeight: FontWeight.w400,
                ),
            menuStyle: MenuStyle(
              maximumSize:
                  const WidgetStatePropertyAll(Size(double.infinity, 250)),
              elevation: const WidgetStatePropertyAll(10),
              shadowColor:
                  WidgetStatePropertyAll(Colors.black.withOpacity(0.4)),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).cardColor,
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              alignment: Alignment.bottomLeft,
              visualDensity: VisualDensity.compact,
            ),
            inputDecorationTheme: InputDecorationTheme(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: Corners.s8Border,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: Corners.s8Border,
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
                borderRadius: Corners.s8Border,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
                borderRadius: Corners.s8Border,
              ),
            ),
            onSelected: (v) async {
              v != null ? widget.onChanged?.call(v) : null;
            },
          ),
        ),
        if (widget.actions?.isNotEmpty == true) ...[
          const HSpace(16),
          SeparatedRow(
            separatorBuilder: () => const HSpace(8),
            children: widget.actions!,
          ),
        ],
      ],
    );
  }
}
