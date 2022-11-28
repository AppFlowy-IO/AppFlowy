import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/select_option_editor_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/color_extension.dart';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../../../layout/sizes.dart';
import '../../common/text_field.dart';
import '../../header/type_option/select_option_editor.dart';
import 'extension.dart';
import 'text_field.dart';

const double _editorPanelWidth = 300;

class SelectOptionCellEditor extends StatefulWidget {
  final GridSelectOptionCellController cellController;
  static double editorPanelWidth = 300;

  const SelectOptionCellEditor({required this.cellController, Key? key})
      : super(key: key);

  @override
  State<SelectOptionCellEditor> createState() => _SelectOptionCellEditorState();
}

class _SelectOptionCellEditorState extends State<SelectOptionCellEditor> {
  late PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionCellEditorBloc(
        cellController: widget.cellController,
      )..add(const SelectOptionEditorEvent.initial()),
      child: BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(6.0),
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverToBoxAdapter(
                  child: _TextField(popoverMutex: popoverMutex),
                ),
                const SliverToBoxAdapter(child: TypeOptionSeparator()),
                const SliverToBoxAdapter(child: VSpace(6)),
                const SliverToBoxAdapter(child: _Title()),
                SliverToBoxAdapter(
                  child: _OptionList(popoverMutex: popoverMutex),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const _OptionList({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        List<Widget> cells = [];
        cells.addAll(state.options.map((option) {
          return _SelectOptionCell(
            option: option,
            isSelected: state.selectedOptions.contains(option),
            popoverMutex: popoverMutex,
          );
        }).toList());

        state.createOption.fold(
          () => null,
          (createOption) {
            cells.add(_CreateOptionCell(name: createOption));
          },
        );

        final list = ListView.separated(
          shrinkWrap: true,
          controller: ScrollController(),
          itemCount: cells.length,
          separatorBuilder: (context, index) {
            return VSpace(GridSize.typeOptionSeparatorHeight);
          },
          physics: StyledScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return cells[index];
          },
        );

        return Padding(
          padding: const EdgeInsets.all(3.0),
          child: list,
        );
      },
    );
  }
}

class _TextField extends StatelessWidget {
  final PopoverMutex popoverMutex;
  final TextfieldTagsController _tagController = TextfieldTagsController();

  _TextField({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        final optionMap = LinkedHashMap<String, SelectOptionPB>.fromIterable(
            state.selectedOptions,
            key: (option) => option.name,
            value: (option) => option);

        return SizedBox(
          height: 52,
          child: SelectOptionTextField(
            options: state.options,
            selectedOptionMap: optionMap,
            distanceToText: _editorPanelWidth * 0.7,
            maxLength: 30,
            tagController: _tagController,
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
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(SelectOptionEditorEvent.selectMultipleOptions(
                    tagNames,
                    remainder,
                  ));
            },
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FlowyText.medium(
          LocaleKeys.grid_selectOption_panelTitle.tr(),
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _CreateOptionCell extends StatelessWidget {
  final String name;
  const _CreateOptionCell({required this.name, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlowyText.medium(
          LocaleKeys.grid_selectOption_create.tr(),
          color: Theme.of(context).hintColor,
        ),
        const HSpace(10),
        SelectOptionTag(
          name: name,
          color: AFThemeExtension.of(context).lightGreyHover,
          onSelected: () => context
              .read<SelectOptionCellEditorBloc>()
              .add(SelectOptionEditorEvent.newOption(name)),
        ),
      ],
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
    return AppFlowyPopover(
      controller: _popoverController,
      offset: const Offset(20, 0),
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      mutex: widget.popoverMutex,
      child: SizedBox(
        height: GridSize.typeOptionItemHeight,
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
                padding: const EdgeInsets.only(right: 6),
                child: svgWidget("grid/checkmark"),
              ),
            FlowyIconButton(
              width: 30,
              onPressed: () => _popoverController.show(),
              hoverColor: Colors.transparent,
              iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              icon: svgWidget(
                "editor/details",
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionTypeOptionEditor(
          option: widget.option,
          onDeleted: () {
            context
                .read<SelectOptionCellEditorBloc>()
                .add(SelectOptionEditorEvent.deleteOption(widget.option));
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
