import 'package:app_flowy/workspace/application/grid/cell_bloc/selection_editor_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
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

import 'extension.dart';

class SelectionEditor extends StatelessWidget {
  final GridCellData cellData;
  const SelectionEditor({required this.cellData, Key? key}) : super(key: key);

  void show(BuildContext context) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.loose(const Size(240, 200)),
      ),
      identifier: toString(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectionEditorBloc(gridId: cellData.gridId, field: cellData.field),
      child: BlocBuilder<SelectionEditorBloc, SelectionEditorState>(
        builder: (context, state) {
          return Column(
            children: const [
              _Title(),
              VSpace(10),
              _OptionList(),
            ],
          );
        },
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionEditorBloc, SelectionEditorState>(
      builder: (context, state) {
        final cells = state.options.map((option) => _SelectionCell(option)).toList();
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

class _Title extends StatelessWidget {
  const _Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyText.medium(LocaleKeys.grid_selectOption_pannelTitle.tr(), fontSize: 12),
    );
  }
}

class _SelectionCell extends StatelessWidget {
  final SelectOption option;
  const _SelectionCell(this.option, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    // return FlowyButton(
    //   text: FlowyText.medium(fieldType.title(), fontSize: 12),
    //   hoverColor: theme.hover,
    //   onTap: () => onSelectField(fieldType),
    //   leftIcon: svgWidget(fieldType.iconName(), color: theme.iconColor),
    // );

    return InkWell(
      onTap: () {},
      child: FlowyHover(
        config: HoverDisplayConfig(hoverColor: theme.hover),
        builder: (_, onHover) {
          return SelectionBadge(option: option);
        },
      ),
    );
  }
}

class SelectionBadge extends StatelessWidget {
  final SelectOption option;
  const SelectionBadge({required this.option, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: option.color.make(context),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: FlowyText.medium(option.name, fontSize: 12),
    );
  }
}
