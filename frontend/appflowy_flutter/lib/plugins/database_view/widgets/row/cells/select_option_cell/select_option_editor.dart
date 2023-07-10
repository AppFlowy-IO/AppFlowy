import 'dart:collection';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../../../grid/presentation/widgets/common/type_option_separator.dart';
import '../../../../grid/presentation/widgets/header/type_option/select_option_editor.dart';
import 'extension.dart';
import 'select_option_editor_bloc.dart';
import 'text_field.dart';

const double _editorPanelWidth = 300;
const double _padding = 12.0;

class SelectOptionCellEditor extends StatefulWidget {
  final SelectOptionCellController cellController;
  static double editorPanelWidth = 300;

  const SelectOptionCellEditor({required this.cellController, Key? key})
      : super(key: key);

  @override
  State<SelectOptionCellEditor> createState() => _SelectOptionCellEditorState();
}

class _SelectOptionCellEditorState extends State<SelectOptionCellEditor> {
  final popoverMutex = PopoverMutex();
  final tagController = TextfieldTagsController();

  @override
  void dispose() {
    popoverMutex.dispose();
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionCellEditorBloc(
        cellController: widget.cellController,
      )..add(const SelectOptionEditorEvent.initial()),
      child: BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TextField(
                popoverMutex: popoverMutex,
                tagController: tagController,
              ),
              const TypeOptionSeparator(spacing: 0.0),
              Flexible(
                child: _OptionList(
                  popoverMutex: popoverMutex,
                  tagController: tagController,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  final PopoverMutex popoverMutex;
  final TextfieldTagsController tagController;

  const _OptionList({
    required this.popoverMutex,
    required this.tagController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        final cells = [
          _Title(onPressedAddButton: () => onPressedAddButton(context)),
          ...state.options.map(
            (option) => _SelectOptionCell(
              option: option,
              isSelected: state.selectedOptions.contains(option),
              popoverMutex: popoverMutex,
            ),
          ),
        ];

        state.createOption.fold(
          () => null,
          (createOption) {
            cells.add(_CreateOptionCell(name: createOption));
          },
        );

        return ListView.separated(
          shrinkWrap: true,
          controller: ScrollController(),
          itemCount: cells.length,
          separatorBuilder: (_, __) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          physics: StyledScrollPhysics(),
          itemBuilder: (_, int index) => cells[index],
          padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
        );
      },
    );
  }

  void onPressedAddButton(BuildContext context) {
    final text = tagController.textEditingController?.text;
    if (text != null) {
      context.read<SelectOptionCellEditorBloc>().add(
            SelectOptionEditorEvent.trySelectOption(text),
          );
    }
    tagController.textEditingController?.clear();
  }
}

class _TextField extends StatelessWidget {
  final PopoverMutex popoverMutex;
  final TextfieldTagsController tagController;

  const _TextField({
    required this.popoverMutex,
    required this.tagController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        final optionMap = LinkedHashMap<String, SelectOptionPB>.fromIterable(
          state.selectedOptions,
          key: (option) => option.name,
          value: (option) => option,
        );

        return Padding(
          padding: const EdgeInsets.all(_padding),
          child: SelectOptionTextField(
            options: state.options,
            selectedOptionMap: optionMap,
            distanceToText: _editorPanelWidth * 0.7,
            tagController: tagController,
            textSeparators: const [','],
            onClick: () => popoverMutex.close(),
            newText: (text) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(SelectOptionEditorEvent.filterOption(text));
            },
            onSubmitted: (tagName) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(SelectOptionEditorEvent.trySelectOption(tagName));
            },
            onPaste: (tagNames, remainder) {
              context.read<SelectOptionCellEditorBloc>().add(
                    SelectOptionEditorEvent.selectMultipleOptions(
                      tagNames,
                      remainder,
                    ),
                  );
            },
            onRemove: (optionName) {
              context.read<SelectOptionCellEditorBloc>().add(
                    SelectOptionEditorEvent.unSelectOption(
                      optionMap[optionName]!.id,
                    ),
                  );
            },
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.onPressedAddButton,
  });

  final VoidCallback onPressedAddButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FlowyText.medium(
              LocaleKeys.grid_selectOption_panelTitle.tr(),
              color: Theme.of(context).hintColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
              ),
              child: FlowyIconButton(
                onPressed: onPressedAddButton,
                width: 18,
                icon: svgWidget(
                  'home/add',
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOptionCell extends StatelessWidget {
  const _CreateOptionCell({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
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
                  name: name,
                  color: AFThemeExtension.of(context).greyHover,
                  onSelected: () => context
                      .read<SelectOptionCellEditorBloc>()
                      .add(SelectOptionEditorEvent.newOption(name)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectOptionCell extends StatefulWidget {
  final SelectOptionPB option;
  final PopoverMutex popoverMutex;
  final bool isSelected;

  const _SelectOptionCell({
    required this.option,
    required this.isSelected,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<_SelectOptionCell> createState() => _SelectOptionCellState();
}

class _SelectOptionCellState extends State<_SelectOptionCell> {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: GridSize.popoverItemHeight,
      child: SelectOptionTagCell(
        option: widget.option,
        onSelected: (option) {
          if (widget.isSelected) {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionEditorEvent.unSelectOption(option.id));
          } else {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionEditorEvent.selectOption(option.id));
          }
        },
        children: [
          if (widget.isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: svgWidget("grid/checkmark"),
            ),
          FlowyIconButton(
            onPressed: () => _popoverController.show(),
            hoverColor: Colors.transparent,
            iconPadding: const EdgeInsets.symmetric(horizontal: 6.0),
            icon: svgWidget(
              "editor/details",
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
    );
    return AppFlowyPopover(
      controller: _popoverController,
      offset: const Offset(8, 0),
      margin: EdgeInsets.zero,
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(200, 470)),
      mutex: widget.popoverMutex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: child,
      ),
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionTypeOptionEditor(
          option: widget.option,
          onDeleted: () {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionEditorEvent.deleteOption(widget.option));
            PopoverContainer.of(popoverContext).close();
          },
          onUpdated: (updatedOption) {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionEditorEvent.updateOption(updatedOption));
          },
          key: ValueKey(
            widget.option.id,
          ), // Use ValueKey to refresh the UI, otherwise, it will remain the old value.
        );
      },
    );
  }
}
