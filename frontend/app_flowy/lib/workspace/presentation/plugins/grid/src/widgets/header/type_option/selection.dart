import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/option_pannel_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/selection_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_tyep_switcher.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import 'widget.dart';

class SingleSelectTypeOptionBuilder extends TypeOptionBuilder {
  SingleSelectTypeOption typeOption;

  SingleSelectTypeOptionBuilder(TypeOptionData typeOptionData)
      : typeOption = SingleSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => SingleSelectTypeOptionWidget(typeOption);
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  final SingleSelectTypeOption typeOption;
  const SingleSelectTypeOptionWidget(this.typeOption, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SelectionTypeOptionBloc>(),
      child: OptionPannel(options: typeOption.options),
    );
  }
}

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  MultiSelectTypeOption typeOption;

  MultiSelectTypeOptionBuilder(TypeOptionData typeOptionData)
      : typeOption = MultiSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => MultiSelectTypeOptionWidget(typeOption);
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final MultiSelectTypeOption typeOption;
  const MultiSelectTypeOptionWidget(this.typeOption, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SelectionTypeOptionBloc>(),
      child: OptionPannel(options: typeOption.options),
    );
  }
}

class OptionPannel extends StatelessWidget {
  final List<SelectOption> options;
  const OptionPannel({required this.options, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OptionPannelBloc(options: options),
      child: BlocBuilder<OptionPannelBloc, OptionPannelState>(
        builder: (context, state) {
          List<Widget> children = [const OptionTitle()];
          if (state.isAddingOption) {
            children.add(const _AddOptionTextField());
          }

          if (state.options.isEmpty && !state.isAddingOption) {
            children.add(const _AddOptionButton());
          }

          if (state.options.isNotEmpty) {
            children.add(const _OptionList());
          }

          return Column(children: children);
        },
      ),
    );
  }
}

class OptionTitle extends StatelessWidget {
  const OptionTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return BlocBuilder<OptionPannelBloc, OptionPannelState>(
      buildWhen: (previous, current) => previous.options.length != current.options.length,
      builder: (context, state) {
        List<Widget> children = [FlowyText.medium(LocaleKeys.grid_field_optionTitle.tr(), fontSize: 12)];

        if (state.options.isNotEmpty && state.isAddingOption == false) {
          children.add(FlowyButton(
            text: FlowyText.medium(LocaleKeys.grid_field_addOption.tr(), fontSize: 12),
            hoverColor: theme.hover,
            onTap: () {
              context.read<OptionPannelBloc>().add(const OptionPannelEvent.beginAddingOption());
            },
            rightIcon: svg("grid/more", color: theme.iconColor),
          ));
        }

        return SizedBox(
          height: GridSize.typeOptionItemHeight,
          child: Row(children: children),
        );
      },
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OptionPannelBloc, OptionPannelState>(
      builder: (context, state) {
        final optionItems = state.options.map((option) {
          return _OptionItem(option: option);
        }).toList();

        return SizedBox(
          width: 120,
          child: ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            separatorBuilder: (context, index) {
              return VSpace(GridSize.typeOptionSeparatorHeight);
            },
            itemCount: optionItems.length,
            itemBuilder: (BuildContext context, int index) {
              return optionItems[index];
            },
          ),
        );
      },
    );
  }
}

class _OptionItem extends StatelessWidget {
  final SelectOption option;
  const _OptionItem({required this.option, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(option.name, fontSize: 12),
        hoverColor: theme.hover,
        onTap: () {},
        rightIcon: svg("grid/more", color: theme.iconColor),
      ),
    );
  }
}

class _AddOptionButton extends StatelessWidget {
  const _AddOptionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_addSelectOption.tr(), fontSize: 12),
        hoverColor: theme.hover,
        onTap: () {
          context.read<OptionPannelBloc>().add(const OptionPannelEvent.beginAddingOption());
        },
        leftIcon: svg("home/add", color: theme.iconColor),
      ),
    );
  }
}

class _AddOptionTextField extends StatelessWidget {
  const _AddOptionTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NameTextField(
        name: "",
        onCanceled: () {
          context.read<OptionPannelBloc>().add(const OptionPannelEvent.endAddingOption());
        },
        onDone: (optionName) {
          context.read<OptionPannelBloc>().add(OptionPannelEvent.createOption(optionName));
        });
  }
}
