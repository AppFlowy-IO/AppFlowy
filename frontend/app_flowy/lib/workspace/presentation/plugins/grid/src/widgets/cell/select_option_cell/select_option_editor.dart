import 'dart:collection';
import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/cell/select_option_editor_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/select_option_editor.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/common/text_field.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:textfield_tags/textfield_tags.dart';

import 'extension.dart';
import 'text_field.dart';

const double _editorPannelWidth = 300;

class SelectOptionCellEditor extends StatelessWidget with FlowyOverlayDelegate {
  final GridSelectOptionCellContext cellContext;
  final VoidCallback onDismissed;

  const SelectOptionCellEditor({
    required this.cellContext,
    required this.onDismissed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionCellEditorBloc(
        cellContext: cellContext,
      )..add(const SelectOptionEditorEvent.initial()),
      child: BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
        builder: (context, state) {
          return CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(child: _TextField()),
              const SliverToBoxAdapter(child: VSpace(6)),
              const SliverToBoxAdapter(child: TypeOptionSeparator()),
              const SliverToBoxAdapter(child: VSpace(6)),
              const SliverToBoxAdapter(child: _Title()),
              const SliverToBoxAdapter(child: _OptionList()),
            ],
          );
        },
      ),
    );
  }

  static void show(
    BuildContext context,
    GridSelectOptionCellContext cellContext,
    VoidCallback onDismissed,
  ) {
    SelectOptionCellEditor.remove(context);
    final editor = SelectOptionCellEditor(
      cellContext: cellContext,
      onDismissed: onDismissed,
    );

    //
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: SizedBox(width: _editorPannelWidth, child: editor),
        constraints: BoxConstraints.loose(const Size(_editorPannelWidth, 300)),
      ),
      identifier: SelectOptionCellEditor.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithCenterAligned,
      delegate: editor,
    );
  }

  static void remove(BuildContext context) {
    FlowyOverlay.of(context).remove(identifier());
  }

  static String identifier() {
    return (SelectOptionCellEditor).toString();
  }

  @override
  bool asBarrier() => true;

  @override
  void didRemove() => onDismissed();
}

class _OptionList extends StatelessWidget {
  const _OptionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        List<Widget> cells = [];
        cells.addAll(state.options.map((option) {
          return _SelectOptionCell(option, state.selectedOptions.contains(option));
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
  final TextfieldTagsController _tagController = TextfieldTagsController();

  _TextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        final optionMap = LinkedHashMap<String, SelectOption>.fromIterable(state.selectedOptions,
            key: (option) => option.name, value: (option) => option);

        return SizedBox(
          height: 42,
          child: SelectOptionTextField(
            options: state.options,
            selectedOptionMap: optionMap,
            distanceToText: _editorPannelWidth * 0.7,
            tagController: _tagController,
            newText: (text) {
              context.read<SelectOptionCellEditorBloc>().add(SelectOptionEditorEvent.filterOption(text));
            },
            onNewTag: (tagName) {
              context.read<SelectOptionCellEditorBloc>().add(SelectOptionEditorEvent.newOption(tagName));
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
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FlowyText.medium(
          LocaleKeys.grid_selectOption_pannelTitle.tr(),
          fontSize: 12,
          color: theme.shader3,
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
    final theme = context.watch<AppTheme>();
    return Row(
      children: [
        FlowyText.medium(
          LocaleKeys.grid_selectOption_create.tr(),
          fontSize: 12,
          color: theme.shader3,
        ),
        const HSpace(10),
        SelectOptionTag(
          name: name,
          color: theme.shader6,
        ),
      ],
    );
  }
}

class _SelectOptionCell extends StatelessWidget {
  final SelectOption option;
  final bool isSelected;
  const _SelectOptionCell(this.option, this.isSelected, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SelectOptionTagCell(
              option: option,
              onSelected: (option) {
                context.read<SelectOptionCellEditorBloc>().add(SelectOptionEditorEvent.selectOption(option.id));
              },
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: svgWidget("grid/checkmark"),
                  ),
              ],
            ),
          ),
          FlowyIconButton(
            width: 30,
            onPressed: () => _showEditPannel(context),
            iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            icon: svgWidget("editor/details", color: theme.iconColor),
          )
        ],
      ),
    );
  }

  void _showEditPannel(BuildContext context) {
    final pannel = SelectOptionTypeOptionEditor(
      option: option,
      onDeleted: () {
        context.read<SelectOptionCellEditorBloc>().add(SelectOptionEditorEvent.deleteOption(option));
      },
      onUpdated: (updatedOption) {
        context.read<SelectOptionCellEditorBloc>().add(SelectOptionEditorEvent.updateOption(updatedOption));
      },
      key: ValueKey(option.id), // Use ValueKey to refresh the UI, otherwise, it will remain the old value.
    );
    final overlayIdentifier = (SelectOptionTypeOptionEditor).toString();

    FlowyOverlay.of(context).remove(overlayIdentifier);
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: pannel,
        constraints: BoxConstraints.loose(const Size(200, 300)),
      ),
      identifier: overlayIdentifier,
      anchorContext: context,
      anchorDirection: AnchorDirection.rightWithCenterAligned,
      anchorOffset: Offset(2 * overlayContainerPadding.left, 0),
    );
  }
}
