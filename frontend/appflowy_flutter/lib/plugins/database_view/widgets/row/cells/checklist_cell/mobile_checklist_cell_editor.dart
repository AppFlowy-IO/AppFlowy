import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_cell_bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileChecklistCellEditScreen extends StatefulWidget {
  const MobileChecklistCellEditScreen({
    super.key,
    required this.cellController,
  });

  final ChecklistCellController cellController;

  @override
  State<MobileChecklistCellEditScreen> createState() =>
      _MobileChecklistCellEditScreenState();
}

class _MobileChecklistCellEditScreenState
    extends State<MobileChecklistCellEditScreen> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(height: 420),
      child: BlocProvider(
        create: (context) => ChecklistCellBloc(
          cellController: widget.cellController,
        )..add(const ChecklistCellEvent.initial()),
        child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DragHandler(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildHeader(context),
                ),
                const Divider(),
                const Expanded(child: _TaskList()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    const iconWidth = 36.0;
    const height = 44.0;
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FlowyIconButton(
            icon: const FlowySvg(
              FlowySvgs.close_s,
              size: Size.square(iconWidth),
            ),
            width: iconWidth,
            iconPadding: EdgeInsets.zero,
            onPressed: () => context.pop(),
          ),
        ),
        SizedBox(
          height: 44.0,
          child: Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              LocaleKeys.grid_field_checklistFieldName.tr(),
              fontSize: 18,
            ),
          ),
        ),
      ].map((e) => SizedBox(height: height, child: e)).toList(),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
      builder: (context, state) {
        final cells = <Widget>[];
        cells.addAll(
          state.tasks
              .mapIndexed(
                (index, task) => _ChecklistItem(
                  task: task,
                  autofocus: state.newTask && index == state.tasks.length - 1,
                ),
              )
              .toList(),
        );
        cells.add(const _NewTaskButton());

        return ListView.separated(
          shrinkWrap: true,
          itemCount: cells.length,
          separatorBuilder: (_, __) => const VSpace(8),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, int index) => cells[index],
          padding: const EdgeInsets.only(bottom: 12.0),
        );
      },
    );
  }
}

class _ChecklistItem extends StatefulWidget {
  const _ChecklistItem({required this.task, required this.autofocus});

  final ChecklistSelectOption task;
  final bool autofocus;

  @override
  State<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<_ChecklistItem> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceOnChanged;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.task.data.name);
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.data.name != oldWidget.task.data.name &&
        !_focusNode.hasFocus) {
      _textController.text = widget.task.data.name;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => context
                .read<ChecklistCellBloc>()
                .add(ChecklistCellEvent.selectTask(widget.task.data)),
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: FlowySvg(
                  widget.task.isSelected
                      ? FlowySvgs.check_filled_s
                      : FlowySvgs.uncheck_s,
                  size: const Size.square(20.0),
                  blendMode: BlendMode.dst,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: LocaleKeys.grid_checklist_taskHint.tr(),
              ),
              onChanged: _debounceOnChangedText,
              onSubmitted: (description) {
                _submitUpdateTaskDescription(description);
              },
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _showDeleteTaskBottomSheet,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: FlowySvg(
                  FlowySvgs.three_dots_s,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _debounceOnChangedText(String text) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(const Duration(milliseconds: 300), () {
      _submitUpdateTaskDescription(text);
    });
  }

  void _submitUpdateTaskDescription(String description) {
    context.read<ChecklistCellBloc>().add(
          ChecklistCellEvent.updateTaskName(
            widget.task.data,
            description.trim(),
          ),
        );
  }

  void _showDeleteTaskBottomSheet() {
    showMobileBottomSheet(
      context,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: InkWell(
              onTap: () {
                context.read<ChecklistCellBloc>().add(
                      ChecklistCellEvent.deleteTask(widget.task.data),
                    );
                context.pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    FlowySvg(
                      FlowySvgs.m_delete_m,
                      size: const Size.square(20),
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const HSpace(8),
                    FlowyText(
                      LocaleKeys.button_delete.tr(),
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 9),
        ],
      ),
    );
  }
}

class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context
              .read<ChecklistCellBloc>()
              .add(const ChecklistCellEvent.createNewTask(""));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            children: [
              const FlowySvg(FlowySvgs.add_s, size: Size.square(20)),
              const HSpace(11),
              FlowyText(LocaleKeys.grid_checklist_addNew.tr(), fontSize: 15),
            ],
          ),
        ),
      ),
    );
  }
}
