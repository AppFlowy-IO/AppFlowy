import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/cell/bloc/checklist_cell_bloc.dart';

class ChecklistCellCheckIcon extends StatelessWidget {
  const ChecklistCellCheckIcon({
    super.key,
    required this.task,
  });

  final ChecklistSelectOption task;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: FlowyIconButton(
        width: 32,
        icon: FlowySvg(
          task.isSelected ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
          blendMode: BlendMode.dst,
        ),
        hoverColor: Colors.transparent,
        onPressed: () => context.read<ChecklistCellBloc>().add(
              ChecklistCellEvent.selectTask(task.data.id),
            ),
      ),
    );
  }
}

class ChecklistCellTextfield extends StatelessWidget {
  const ChecklistCellTextfield({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.autofocus,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback? onSubmitted;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    const contentPadding = EdgeInsets.symmetric(
      vertical: 6.0,
      horizontal: 2.0,
    );
    return TextField(
      controller: textController,
      focusNode: focusNode,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: null,
      decoration: InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: contentPadding,
        hintText: LocaleKeys.grid_checklist_taskHint.tr(),
      ),
      textInputAction: onSubmitted == null ? TextInputAction.next : null,
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}

class ChecklistCellDeleteButton extends StatefulWidget {
  const ChecklistCellDeleteButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<ChecklistCellDeleteButton> createState() =>
      _ChecklistCellDeleteButtonState();
}

class _ChecklistCellDeleteButtonState extends State<ChecklistCellDeleteButton> {
  final _materialStatesController = WidgetStatesController();

  @override
  void dispose() {
    _materialStatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      onHover: (_) => setState(() {}),
      onFocusChange: (_) => setState(() {}),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(32)),
        minimumSize: const WidgetStatePropertyAll(Size.square(32)),
        maximumSize: const WidgetStatePropertyAll(Size.square(32)),
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.contains(WidgetState.focused)) {
            return AFThemeExtension.of(context).greyHover;
          }
          return Colors.transparent;
        }),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Corners.s6Border),
        ),
      ),
      statesController: _materialStatesController,
      child: FlowySvg(
        FlowySvgs.delete_s,
        color: _materialStatesController.value.contains(WidgetState.hovered) ||
                _materialStatesController.value.contains(WidgetState.focused)
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }
}
