import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/sort/sort_editor_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import 'sort_choice_button.dart';
import 'sort_info.dart';

class SortEditor extends StatelessWidget {
  final String viewId;
  final List<SortInfo> sortInfos;
  final GridFieldController fieldController;
  const SortEditor({
    required this.viewId,
    required this.fieldController,
    required this.sortInfos,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SortEditorBloc(
        viewId: viewId,
        fieldController: fieldController,
        sortInfos: sortInfos,
      )..add(const SortEditorEvent.initial()),
      child: BlocBuilder<SortEditorBloc, SortEditorState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: const [
                _SortList(),
                _AddSortButton(),
                _DeleteSortButton(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SortList extends StatelessWidget {
  const _SortList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        final List<Widget> children = state.sortInfos
            .map((info) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _SortItem(sortInfo: info),
                ))
            .toList();

        return Column(
          children: children,
        );
      },
    );
  }
}

class _SortItem extends StatelessWidget {
  final SortInfo sortInfo;
  const _SortItem({required this.sortInfo, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameButton = SortChoiceButton(
      text: sortInfo.fieldInfo.name,
      onTap: () {},
    );

    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: svgWidget("home/arrow_left"),
    );

    final orderButton = SortChoiceButton(
      text: textFromCondition(sortInfo.sortPB.condition),
      rightIcon: arrow,
      onTap: () {},
    );

    final deleteButton = FlowyIconButton(
      width: 26,
      onPressed: () {},
      iconPadding: const EdgeInsets.all(5),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      icon: svgWidget(
        "home/close",
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    return Row(
      children: [
        SizedBox(height: 26, child: nameButton),
        const HSpace(6),
        SizedBox(height: 26, child: orderButton),
        const Spacer(),
        deleteButton
      ],
    );
  }

  String textFromCondition(GridSortConditionPB condition) {
    switch (condition) {
      case GridSortConditionPB.Ascending:
        return LocaleKeys.grid_sort_ascending.tr();
      case GridSortConditionPB.Descending:
        return LocaleKeys.grid_sort_descending.tr();
    }
    return "";
  }
}

class _AddSortButton extends StatelessWidget {
  const _AddSortButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_sort_addSort.tr()),
        onTap: () {},
        leftIcon: svgWidget(
          "home/add",
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DeleteSortButton extends StatelessWidget {
  const _DeleteSortButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        return SizedBox(
          height: 30,
          child: FlowyButton(
            text: FlowyText.medium(LocaleKeys.grid_sort_deleteSort.tr()),
            onTap: () {
              context
                  .read<SortEditorBloc>()
                  .add(const SortEditorEvent.deleteAllSorts());
            },
            leftIcon: svgWidget(
              "editor/delete",
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
