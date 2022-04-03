import 'package:app_flowy/workspace/application/grid/field/type_option/edit_option_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/widget.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class EditSelectOptionPannel extends StatelessWidget {
  final SelectOption option;
  final VoidCallback onDeleted;
  final Function(SelectOption) onUpdated;
  const EditSelectOptionPannel({
    required this.option,
    required this.onDeleted,
    required this.onUpdated,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditOptionBloc(option: option),
      child: MultiBlocListener(
        listeners: [
          BlocListener<EditOptionBloc, EditOptionState>(
            listenWhen: (p, c) => p.deleted != c.deleted,
            listener: (context, state) {
              state.deleted.fold(() => null, (_) => onDeleted());
            },
          ),
          BlocListener<EditOptionBloc, EditOptionState>(
            listenWhen: (p, c) => p.option != c.option,
            listener: (context, state) {
              onUpdated(state.option);
            },
          ),
        ],
        child: BlocBuilder<EditOptionBloc, EditOptionState>(
          builder: (context, state) {
            List<Widget> slivers = [
              SliverToBoxAdapter(child: _OptionNameTextField(state.option.name)),
              const SliverToBoxAdapter(child: VSpace(10)),
              const SliverToBoxAdapter(child: _DeleteTag()),
              const SliverToBoxAdapter(child: TypeOptionSeparator()),
              SliverToBoxAdapter(child: SelectOptionColorList(selectedColor: state.option.color)),
            ];

            return SizedBox(
              width: 160,
              child: CustomScrollView(
                slivers: slivers,
                controller: ScrollController(),
                physics: StyledScrollPhysics(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeleteTag extends StatelessWidget {
  const _DeleteTag({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_selectOption_deleteTag.tr(), fontSize: 12),
        hoverColor: theme.hover,
        leftIcon: svgWidget("grid/delete", color: theme.iconColor),
        onTap: () {
          context.read<EditOptionBloc>().add(const EditOptionEvent.delete());
        },
      ),
    );
  }
}

class _OptionNameTextField extends StatelessWidget {
  final String name;
  const _OptionNameTextField(this.name, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NameTextField(
      name: name,
      onCanceled: () {},
      onDone: (optionName) {
        context.read<EditOptionBloc>().add(EditOptionEvent.updateName(optionName));
      },
    );
  }
}

class SelectOptionColorList extends StatelessWidget {
  final SelectOptionColor selectedColor;
  const SelectOptionColorList({required this.selectedColor, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = SelectOptionColor.values.map((color) {
      return _SelectOptionColorCell(color: color, isSelected: selectedColor == color);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: GridSize.typeOptionContentInsets,
          child: SizedBox(
            height: GridSize.typeOptionItemHeight,
            child: FlowyText.medium(
              LocaleKeys.grid_selectOption_colorPannelTitle.tr(),
              fontSize: 12,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          controller: ScrollController(),
          separatorBuilder: (context, index) {
            return VSpace(GridSize.typeOptionSeparatorHeight);
          },
          itemCount: cells.length,
          physics: StyledScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return cells[index];
          },
        ),
      ],
    );
  }
}

class _SelectOptionColorCell extends StatelessWidget {
  final SelectOptionColor color;
  final bool isSelected;
  const _SelectOptionColorCell({required this.color, required this.isSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    Widget? checkmark;
    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    final colorIcon = SizedBox.square(
      dimension: 16,
      child: Container(
        decoration: BoxDecoration(
          color: color.color(context),
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(color.optionName(), fontSize: 12),
        hoverColor: theme.hover,
        leftIcon: colorIcon,
        rightIcon: checkmark,
        onTap: () {
          context.read<EditOptionBloc>().add(EditOptionEvent.updateColor(color));
        },
      ),
    );
  }
}

extension SelectOptionColorExtension on SelectOptionColor {
  Color color(BuildContext context) {
    final theme = context.watch<AppTheme>();
    switch (this) {
      case SelectOptionColor.Purple:
        return theme.tint1;
      case SelectOptionColor.Pink:
        return theme.tint2;
      case SelectOptionColor.LightPink:
        return theme.tint3;
      case SelectOptionColor.Orange:
        return theme.tint4;
      case SelectOptionColor.Yellow:
        return theme.tint5;
      case SelectOptionColor.Lime:
        return theme.tint6;
      case SelectOptionColor.Green:
        return theme.tint7;
      case SelectOptionColor.Aqua:
        return theme.tint8;
      case SelectOptionColor.Blue:
        return theme.tint9;
      default:
        throw ArgumentError;
    }
  }

  String optionName() {
    switch (this) {
      case SelectOptionColor.Purple:
        return LocaleKeys.grid_selectOption_purpleColor.tr();
      case SelectOptionColor.Pink:
        return LocaleKeys.grid_selectOption_pinkColor.tr();
      case SelectOptionColor.LightPink:
        return LocaleKeys.grid_selectOption_lightPinkColor.tr();
      case SelectOptionColor.Orange:
        return LocaleKeys.grid_selectOption_orangeColor.tr();
      case SelectOptionColor.Yellow:
        return LocaleKeys.grid_selectOption_yellowColor.tr();
      case SelectOptionColor.Lime:
        return LocaleKeys.grid_selectOption_limeColor.tr();
      case SelectOptionColor.Green:
        return LocaleKeys.grid_selectOption_greenColor.tr();
      case SelectOptionColor.Aqua:
        return LocaleKeys.grid_selectOption_aquaColor.tr();
      case SelectOptionColor.Blue:
        return LocaleKeys.grid_selectOption_blueColor.tr();
      default:
        throw ArgumentError;
    }
  }
}
