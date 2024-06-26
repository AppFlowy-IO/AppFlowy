import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../grid/presentation/widgets/common/type_option_separator.dart';
import '../field/type_option_editor/select/select_option_editor.dart';

import 'extension.dart';
import 'select_option_text_field.dart';

const double _editorPanelWidth = 300;

class SelectOptionCellEditor extends StatefulWidget {
  const SelectOptionCellEditor({super.key, required this.cellController});

  final SelectOptionCellController cellController;

  @override
  State<SelectOptionCellEditor> createState() => _SelectOptionCellEditorState();
}

class _SelectOptionCellEditorState extends State<SelectOptionCellEditor> {
  final textEditingController = TextEditingController();
  final scrollController = ScrollController();
  final popoverMutex = PopoverMutex();
  late final bloc = SelectOptionCellEditorBloc(
    cellController: widget.cellController,
  );
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (node, event) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp when event is! KeyUpEvent:
            if (textEditingController.value.composing.isCollapsed) {
              bloc.add(const SelectOptionCellEditorEvent.focusPreviousOption());
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.arrowDown when event is! KeyUpEvent:
            if (textEditingController.value.composing.isCollapsed) {
              bloc.add(const SelectOptionCellEditorEvent.focusNextOption());
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.escape when event is! KeyUpEvent:
            if (!textEditingController.value.composing.isCollapsed) {
              final end = textEditingController.value.composing.end;
              final text = textEditingController.text;

              textEditingController.value = TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: end),
              );
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.backspace when event is KeyUpEvent:
            if (!textEditingController.text.isNotEmpty) {
              bloc.add(const SelectOptionCellEditorEvent.unSelectLastOption());
              return KeyEventResult.handled;
            }
            break;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    textEditingController.dispose();
    scrollController.dispose();
    bloc.close();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: TextFieldTapRegion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TextField(
              textEditingController: textEditingController,
              scrollController: scrollController,
              focusNode: focusNode,
              popoverMutex: popoverMutex,
            ),
            const TypeOptionSeparator(spacing: 0.0),
            Flexible(
              child: Focus(
                descendantsAreFocusable: false,
                child: _OptionList(
                  textEditingController: textEditingController,
                  popoverMutex: popoverMutex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.textEditingController,
    required this.popoverMutex,
  });

  final TextEditingController textEditingController;
  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SelectOptionCellEditorBloc,
        SelectOptionCellEditorState>(
      listenWhen: (previous, current) =>
          previous.clearFilter != current.clearFilter,
      listener: (context, state) {
        if (state.clearFilter) {
          textEditingController.clear();
          context
              .read<SelectOptionCellEditorBloc>()
              .add(const SelectOptionCellEditorEvent.resetClearFilterFlag());
        }
      },
      buildWhen: (previous, current) =>
          !listEquals(previous.options, current.options) ||
          previous.createSelectOptionSuggestion !=
              current.createSelectOptionSuggestion,
      builder: (context, state) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          proxyDecorator: (child, index, _) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                BlocProvider.value(
                  value: context.read<SelectOptionCellEditorBloc>(),
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
          itemCount: state.options.length,
          onReorderStart: (_) => popoverMutex.close(),
          itemBuilder: (_, int index) {
            final option = state.options[index];
            return _SelectOptionCell(
              key: ValueKey("select_cell_option_list_${option.id}"),
              index: index,
              option: option,
              popoverMutex: popoverMutex,
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex--;
            }
            final fromOptionId = state.options[oldIndex].id;
            final toOptionId = state.options[newIndex].id;
            context.read<SelectOptionCellEditorBloc>().add(
                  SelectOptionCellEditorEvent.reorderOption(
                    fromOptionId,
                    toOptionId,
                  ),
                );
          },
          header: const _Title(),
          footer: state.createSelectOptionSuggestion == null
              ? null
              : _CreateOptionCell(
                  suggestion: state.createSelectOptionSuggestion!,
                ),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
        );
      },
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.textEditingController,
    required this.scrollController,
    required this.focusNode,
    required this.popoverMutex,
  });

  final TextEditingController textEditingController;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionCellEditorState>(
      builder: (context, state) {
        final optionMap = LinkedHashMap<String, SelectOptionPB>.fromIterable(
          state.selectedOptions,
          key: (option) => option.name,
          value: (option) => option,
        );

        return Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SelectOptionTextField(
              options: state.options,
              focusNode: focusNode,
              selectedOptionMap: optionMap,
              distanceToText: _editorPanelWidth * 0.7,
              textController: textEditingController,
              scrollController: scrollController,
              textSeparators: const [','],
              onClick: () => popoverMutex.close(),
              newText: (text) {
                context
                    .read<SelectOptionCellEditorBloc>()
                    .add(SelectOptionCellEditorEvent.filterOption(text));
              },
              onSubmitted: () {
                context
                    .read<SelectOptionCellEditorBloc>()
                    .add(const SelectOptionCellEditorEvent.submitTextField());
                focusNode.requestFocus();
              },
              onPaste: (tagNames, remainder) {
                context.read<SelectOptionCellEditorBloc>().add(
                      SelectOptionCellEditorEvent.selectMultipleOptions(
                        tagNames,
                        remainder,
                      ),
                    );
              },
              onRemove: (optionName) {
                context.read<SelectOptionCellEditorBloc>().add(
                      SelectOptionCellEditorEvent.unSelectOption(
                        optionMap[optionName]!.id,
                      ),
                    );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyText.regular(
          LocaleKeys.grid_selectOption_panelTitle.tr(),
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _SelectOptionCell extends StatefulWidget {
  const _SelectOptionCell({
    super.key,
    required this.option,
    required this.index,
    required this.popoverMutex,
  });

  final SelectOptionPB option;
  final int index;
  final PopoverMutex popoverMutex;

  @override
  State<_SelectOptionCell> createState() => _SelectOptionCellState();
}

class _SelectOptionCellState extends State<_SelectOptionCell> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: _popoverController,
      offset: const Offset(8, 0),
      margin: EdgeInsets.zero,
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(200, 470)),
      mutex: widget.popoverMutex,
      clickHandler: PopoverClickHandler.gestureDetector,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        child: MouseRegion(
          onEnter: (_) {
            context.read<SelectOptionCellEditorBloc>().add(
                  SelectOptionCellEditorEvent.updateFocusedOption(
                    widget.option.id,
                  ),
                );
          },
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: context
                          .watch<SelectOptionCellEditorBloc>()
                          .state
                          .focusedOptionId ==
                      widget.option.id
                  ? AFThemeExtension.of(context).lightGreyHover
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: SelectOptionTagCell(
              option: widget.option,
              index: widget.index,
              onSelected: _onTap,
              children: [
                if (context
                    .watch<SelectOptionCellEditorBloc>()
                    .state
                    .selectedOptions
                    .contains(widget.option))
                  FlowyIconButton(
                    width: 20,
                    hoverColor: Colors.transparent,
                    onPressed: _onTap,
                    icon: FlowySvg(
                      FlowySvgs.check_s,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                FlowyIconButton(
                  onPressed: () => _popoverController.show(),
                  iconPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                  hoverColor: Colors.transparent,
                  icon: FlowySvg(
                    FlowySvgs.three_dots_s,
                    size: const Size.square(16),
                    color: AFThemeExtension.of(context).onBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionEditor(
          option: widget.option,
          onDeleted: () {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionCellEditorEvent.deleteOption(widget.option));
            PopoverContainer.of(popoverContext).close();
          },
          onUpdated: (updatedOption) {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionCellEditorEvent.updateOption(updatedOption));
          },
          key: ValueKey(
            widget.option.id,
          ), // Use ValueKey to refresh the UI, otherwise, it will remain the old value.
        );
      },
    );
  }

  void _onTap() {
    widget.popoverMutex.close();
    if (context
        .read<SelectOptionCellEditorBloc>()
        .state
        .selectedOptions
        .contains(widget.option)) {
      context
          .read<SelectOptionCellEditorBloc>()
          .add(SelectOptionCellEditorEvent.unSelectOption(widget.option.id));
    } else {
      context
          .read<SelectOptionCellEditorBloc>()
          .add(SelectOptionCellEditorEvent.selectOption(widget.option.id));
    }
  }
}

class SelectOptionTagCell extends StatelessWidget {
  const SelectOptionTagCell({
    super.key,
    required this.option,
    required this.onSelected,
    this.children = const [],
    this.index,
  });

  final SelectOptionPB option;
  final VoidCallback onSelected;
  final List<Widget> children;
  final int? index;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (index != null)
          ReorderableDragStartListener(
            index: index!,
            child: MouseRegion(
              cursor: Platform.isWindows
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.grab,
              child: GestureDetector(
                onTap: onSelected,
                child: SizedBox(
                  width: 26,
                  child: Center(
                    child: FlowySvg(
                      FlowySvgs.drag_element_s,
                      size: const Size.square(14),
                      color: AFThemeExtension.of(context).onBackground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelected,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  child: SelectOptionTag(
                    option: option,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _CreateOptionCell extends StatelessWidget {
  const _CreateOptionCell({
    required this.suggestion,
  });

  final CreateSelectOptionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            context.watch<SelectOptionCellEditorBloc>().state.focusedOptionId ==
                    createSelectOptionSuggestionId
                ? AFThemeExtension.of(context).lightGreyHover
                : null,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: GestureDetector(
        onTap: () => context
            .read<SelectOptionCellEditorBloc>()
            .add(const SelectOptionCellEditorEvent.createOption()),
        child: MouseRegion(
          onEnter: (_) {
            context.read<SelectOptionCellEditorBloc>().add(
                  const SelectOptionCellEditorEvent.updateFocusedOption(
                    createSelectOptionSuggestionId,
                  ),
                );
          },
          child: Row(
            children: [
              FlowyText.medium(
                LocaleKeys.grid_selectOption_create.tr(),
                color: Theme.of(context).hintColor,
              ),
              const HSpace(10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectOptionTag(
                    name: suggestion.name,
                    color: suggestion.color.toColor(context),
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
