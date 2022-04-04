import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/cell_bloc/selection_editor_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
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

const double _editorPannelWidth = 300;

class SelectionEditor extends StatelessWidget {
  final CellData cellData;
  final List<SelectOption> options;
  final List<SelectOption> selectedOptions;

  const SelectionEditor({
    required this.cellData,
    required this.options,
    required this.selectedOptions,
    Key? key,
  }) : super(key: key);

  static String identifier() {
    return (SelectionEditor).toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionEditorBloc(
        gridId: cellData.gridId,
        field: cellData.field,
        options: options,
        selectedOptions: selectedOptions,
      ),
      child: BlocBuilder<SelectOptionEditorBloc, SelectOptionEditorState>(
        builder: (context, state) {
          return CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(child: _TextField()),
              const SliverToBoxAdapter(child: VSpace(10)),
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
    CellData cellData,
    List<SelectOption> options,
    List<SelectOption> selectedOptions,
  ) {
    SelectionEditor.hide(context);
    final editor = SelectionEditor(
      cellData: cellData,
      options: options,
      selectedOptions: selectedOptions,
    );

    //
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: SizedBox(width: _editorPannelWidth, child: editor),
        constraints: BoxConstraints.loose(const Size(_editorPannelWidth, 300)),
      ),
      identifier: SelectionEditor.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithCenterAligned,
    );
  }

  static void hide(BuildContext context) {
    FlowyOverlay.of(context).remove(identifier());
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        final cells = state.options.map((option) => _SelectOptionCell(option)).toList();
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
        return list;
      },
    );
  }
}

class _TextField extends StatelessWidget {
  final TextfieldTagsController _tagController = TextfieldTagsController();

  _TextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SelectOptionEditorBloc, SelectOptionEditorState>(
      listener: (context, state) {},
      buildWhen: (previous, current) => previous.field.id != current.field.id,
      builder: (context, state) {
        final optionMap = LinkedHashMap<String, SelectOption>.fromIterable(state.selectedOptions,
            key: (option) => option.name, value: (option) => option);
        return SizedBox(
          height: 42,
          child: SelectOptionTextField(
            optionMap: optionMap,
            distanceToText: _editorPannelWidth * 0.7,
            tagController: _tagController,
            onNewTag: (newTagName) {
              context.read<SelectOptionEditorBloc>().add(SelectOptionEditorEvent.newOption(newTagName));
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

class _SelectOptionCell extends StatelessWidget {
  final SelectOption option;
  const _SelectOptionCell(this.option, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: InkWell(
        onTap: () {},
        child: FlowyHover(
          config: HoverDisplayConfig(hoverColor: theme.hover),
          builder: (_, onHover) {
            List<Widget> children = [
              SelectOptionTag(option: option),
              const Spacer(),
            ];

            if (onHover) {
              children.add(svgWidget("editor/details", color: theme.iconColor));
            }

            return Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(children: children),
            );
          },
        ),
      ),
    );
  }
}
