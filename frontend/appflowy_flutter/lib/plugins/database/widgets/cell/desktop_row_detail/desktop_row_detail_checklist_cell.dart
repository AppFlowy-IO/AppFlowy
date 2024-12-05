import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_textfield.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../editable_cell_skeleton/checklist.dart';

class DesktopRowDetailChecklistCellSkin extends IEditableChecklistCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    PopoverController popoverController,
  ) {
    return ChecklistRowDetailCell(
      context: context,
      cellContainerNotifier: cellContainerNotifier,
      bloc: bloc,
      popoverController: popoverController,
    );
  }
}

class ChecklistRowDetailCell extends StatefulWidget {
  const ChecklistRowDetailCell({
    super.key,
    required this.context,
    required this.cellContainerNotifier,
    required this.bloc,
    required this.popoverController,
  });

  final BuildContext context;
  final CellContainerNotifier cellContainerNotifier;
  final ChecklistCellBloc bloc;
  final PopoverController popoverController;

  @override
  State<ChecklistRowDetailCell> createState() => _ChecklistRowDetailCellState();
}

class _ChecklistRowDetailCellState extends State<ChecklistRowDetailCell> {
  final phantomTextController = TextEditingController();

  @override
  void dispose() {
    phantomTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressAndHideCompleteButton(
            onToggleHideComplete: () => context
                .read<ChecklistCellBloc>()
                .add(const ChecklistCellEvent.toggleShowIncompleteOnly()),
          ),
          const VSpace(2.0),
          _ChecklistItems(
            phantomTextController: phantomTextController,
            onStartCreatingTaskAfter: (index) {
              context
                  .read<ChecklistCellBloc>()
                  .add(ChecklistCellEvent.updatePhantomIndex(index + 1));
            },
          ),
          ChecklistItemControl(
            cellNotifer: widget.cellContainerNotifier,
            onTap: () {
              final bloc = context.read<ChecklistCellBloc>();
              if (bloc.state.phantomIndex == null) {
                phantomTextController.clear();
                bloc.add(
                  ChecklistCellEvent.updatePhantomIndex(
                    bloc.state.showIncompleteOnly
                        ? bloc.state.tasks
                            .where((task) => !task.isSelected)
                            .length
                        : bloc.state.tasks.length,
                  ),
                );
              } else {
                bloc.add(
                  ChecklistCellEvent.createNewTask(
                    phantomTextController.text,
                    index: bloc.state.phantomIndex,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class ProgressAndHideCompleteButton extends StatelessWidget {
  const ProgressAndHideCompleteButton({
    super.key,
    required this.onToggleHideComplete,
  });

  final VoidCallback onToggleHideComplete;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
      buildWhen: (previous, current) =>
          previous.showIncompleteOnly != current.showIncompleteOnly,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
                  builder: (context, state) {
                    return ChecklistProgressBar(
                      tasks: state.tasks,
                      percent: state.percent,
                    );
                  },
                ),
              ),
              const HSpace(6.0),
              FlowyIconButton(
                tooltipText: state.showIncompleteOnly
                    ? LocaleKeys.grid_checklist_showComplete.tr()
                    : LocaleKeys.grid_checklist_hideComplete.tr(),
                width: 32,
                iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                icon: FlowySvg(
                  state.showIncompleteOnly
                      ? FlowySvgs.show_m
                      : FlowySvgs.hide_m,
                  size: const Size.square(16),
                ),
                onPressed: onToggleHideComplete,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChecklistItems extends StatelessWidget {
  const _ChecklistItems({
    required this.phantomTextController,
    required this.onStartCreatingTaskAfter,
  });

  final TextEditingController phantomTextController;
  final void Function(int index) onStartCreatingTaskAfter;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        _CancelCreatingFromPhantomIntent:
            CallbackAction<_CancelCreatingFromPhantomIntent>(
          onInvoke: (_CancelCreatingFromPhantomIntent intent) {
            phantomTextController.clear();
            context
                .read<ChecklistCellBloc>()
                .add(const ChecklistCellEvent.updatePhantomIndex(null));
            return;
          },
        ),
      },
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          final children = _makeChildren(context, state);
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            proxyDecorator: (child, index, _) => Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  BlocProvider.value(
                    value: context.read<ChecklistCellBloc>(),
                    child: child,
                  ),
                  MouseRegion(
                    cursor: Platform.isWindows
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.grabbing,
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
            buildDefaultDragHandles: false,
            itemCount: children.length,
            itemBuilder: (_, index) => children[index],
            onReorder: (from, to) {
              context
                  .read<ChecklistCellBloc>()
                  .add(ChecklistCellEvent.reorderTask(from, to));
            },
          );
        },
      ),
    );
  }

  List<Widget> _makeChildren(BuildContext context, ChecklistCellState state) {
    final children = <Widget>[];

    final tasks = [...state.tasks];

    if (state.showIncompleteOnly) {
      tasks.removeWhere((task) => task.isSelected);
    }

    children.addAll(
      tasks.mapIndexed(
        (index, task) => Padding(
          key: ValueKey('checklist_row_detail_cell_task_${task.data.id}'),
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: ChecklistItem(
            task: task,
            index: index,
            onSubmitted: () {
              onStartCreatingTaskAfter(index);
            },
          ),
        ),
      ),
    );

    if (state.phantomIndex != null) {
      children.insert(
        state.phantomIndex!,
        Padding(
          key: const ValueKey('new_checklist_cell_task'),
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: PhantomChecklistItem(
            index: state.phantomIndex!,
            textController: phantomTextController,
          ),
        ),
      );
    }

    return children;
  }
}

class _CancelCreatingFromPhantomIntent extends Intent {
  const _CancelCreatingFromPhantomIntent();
}

class _SubmitPhantomTaskIntent extends Intent {
  const _SubmitPhantomTaskIntent({
    required this.taskDescription,
    required this.index,
  });

  final String taskDescription;
  final int index;
}

@visibleForTesting
class PhantomChecklistItem extends StatefulWidget {
  const PhantomChecklistItem({
    super.key,
    required this.index,
    required this.textController,
  });

  final int index;
  final TextEditingController textController;

  @override
  State<PhantomChecklistItem> createState() => _PhantomChecklistItemState();
}

class _PhantomChecklistItemState extends State<PhantomChecklistItem> {
  final focusNode = FocusNode();

  bool isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => focusNode.requestFocus());
  }

  void _onTextChanged() => setState(
        () => isComposing = !widget.textController.value.composing.isCollapsed,
      );

  void _onFocusChanged() {
    if (!focusNode.hasFocus) {
      widget.textController.clear();
      Actions.maybeInvoke(
        context,
        const _CancelCreatingFromPhantomIntent(),
      );
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    focusNode.removeListener(_onFocusChanged);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        _SubmitPhantomTaskIntent: CallbackAction<_SubmitPhantomTaskIntent>(
          onInvoke: (_SubmitPhantomTaskIntent intent) {
            context.read<ChecklistCellBloc>().add(
                  ChecklistCellEvent.createNewTask(
                    intent.taskDescription,
                    index: intent.index,
                  ),
                );
            widget.textController.clear();
            return;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: _buildShortcuts(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          decoration: BoxDecoration(
            color: AFThemeExtension.of(context).lightGreyHover,
            borderRadius: Corners.s6Border,
          ),
          child: Center(
            child: ChecklistCellTextfield(
              textController: widget.textController,
              focusNode: focusNode,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    return isComposing
        ? const {}
        : {
            const SingleActivator(LogicalKeyboardKey.enter):
                _SubmitPhantomTaskIntent(
              taskDescription: widget.textController.text,
              index: widget.index,
            ),
            const SingleActivator(LogicalKeyboardKey.escape):
                const _CancelCreatingFromPhantomIntent(),
          };
  }
}

@visibleForTesting
class ChecklistItemControl extends StatelessWidget {
  const ChecklistItemControl({
    super.key,
    required this.cellNotifer,
    required this.onTap,
  });

  final CellContainerNotifier cellNotifer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: cellNotifer,
      child: Consumer<CellContainerNotifier>(
        builder: (buildContext, notifier, _) => TextFieldTapRegion(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 0),
              height: 12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: notifier.isHover
                    ? FlowyTooltip(
                        message: LocaleKeys.grid_checklist_addNew.tr(),
                        child: Row(
                          children: [
                            const Flexible(child: Center(child: Divider())),
                            const HSpace(12.0),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.square(12),
                                maximumSize: const Size.square(12),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: onTap,
                              child: FlowySvg(
                                FlowySvgs.add_s,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const HSpace(12.0),
                            const Flexible(child: Center(child: Divider())),
                          ],
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
