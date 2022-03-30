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
              const SliverToBoxAdapter(child: SelectOptionColorList()),
            ];

            return CustomScrollView(
              slivers: slivers,
              controller: ScrollController(),
              physics: StyledScrollPhysics(),
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
        leftIcon: svg("grid/delete", color: theme.iconColor),
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
  const SelectOptionColorList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final optionItems = SelectOptionColor.values.map((option) {
      // Color color = option.color();
      // var hex = option.color.value.toRadixString(16);
      // if (hex.startsWith('ff')) {
      //   hex = hex.substring(2);
      // }
      // hex = '#$hex';

      return _SelectOptionColorItem(option: option, isSelected: true);
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
          itemCount: optionItems.length,
          physics: StyledScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return optionItems[index];
          },
        ),
      ],
    );
  }
}

class _SelectOptionColorItem extends StatelessWidget {
  final SelectOptionColor option;
  final bool isSelected;
  const _SelectOptionColorItem({required this.option, required this.isSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    Widget? checkmark;
    if (isSelected) {
      checkmark = svg("grid/details", color: theme.iconColor);
    }

    final String hex = '#${option.color(context).value.toRadixString(16)}';
    final colorIcon = SizedBox.square(
      dimension: 16,
      child: Container(
        decoration: BoxDecoration(
          color: option.color(context),
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(option.name(), fontSize: 12),
        hoverColor: theme.hover,
        leftIcon: colorIcon,
        rightIcon: checkmark,
        onTap: () {
          context.read<EditOptionBloc>().add(EditOptionEvent.updateColor(hex));
        },
      ),
    );
  }
}

enum SelectOptionColor {
  purple,
  pink,
  lightPink,
  orange,
  yellow,
  lime,
  green,
  aqua,
  blue,
}

extension SelectOptionColorExtension on SelectOptionColor {
  Color color(BuildContext context) {
    final theme = context.watch<AppTheme>();
    switch (this) {
      case SelectOptionColor.purple:
        return theme.tint1;
      case SelectOptionColor.pink:
        return theme.tint2;
      case SelectOptionColor.lightPink:
        return theme.tint3;
      case SelectOptionColor.orange:
        return theme.tint4;
      case SelectOptionColor.yellow:
        return theme.tint5;
      case SelectOptionColor.lime:
        return theme.tint6;
      case SelectOptionColor.green:
        return theme.tint7;
      case SelectOptionColor.aqua:
        return theme.tint8;
      case SelectOptionColor.blue:
        return theme.tint9;
    }
  }

  String name() {
    switch (this) {
      case SelectOptionColor.purple:
        return LocaleKeys.grid_selectOption_purpleColor.tr();
      case SelectOptionColor.pink:
        return LocaleKeys.grid_selectOption_pinkColor.tr();
      case SelectOptionColor.lightPink:
        return LocaleKeys.grid_selectOption_lightPinkColor.tr();
      case SelectOptionColor.orange:
        return LocaleKeys.grid_selectOption_orangeColor.tr();
      case SelectOptionColor.yellow:
        return LocaleKeys.grid_selectOption_yellowColor.tr();
      case SelectOptionColor.lime:
        return LocaleKeys.grid_selectOption_limeColor.tr();
      case SelectOptionColor.green:
        return LocaleKeys.grid_selectOption_greenColor.tr();
      case SelectOptionColor.aqua:
        return LocaleKeys.grid_selectOption_aquaColor.tr();
      case SelectOptionColor.blue:
        return LocaleKeys.grid_selectOption_blueColor.tr();
    }
  }
}
