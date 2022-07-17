import 'package:app_flowy/workspace/application/grid/field/type_option/select_option_type_option_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/select_option_cell/extension.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/common/text_field.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import 'builder.dart';
import 'select_option_editor.dart';

class SelectOptionTypeOptionWidget extends StatelessWidget {
  final List<SelectOptionPB> options;
  final VoidCallback beginEdit;
  final TypeOptionOverlayDelegate overlayDelegate;
  final SelectOptionTypeOptionAction typeOptionAction;

  const SelectOptionTypeOptionWidget({
    required this.options,
    required this.beginEdit,
    required this.overlayDelegate,
    required this.typeOptionAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionTypeOptionBloc(options: options, typeOptionAction: typeOptionAction),
      child: BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
        builder: (context, state) {
          List<Widget> children = [
            const TypeOptionSeparator(),
            const OptionTitle(),
            if (state.isEditingOption)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _CreateOptionTextField(),
              ),
            if (state.options.isEmpty && !state.isEditingOption) const _AddOptionButton(),
            _OptionList(overlayDelegate)
          ];

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
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        List<Widget> children = [FlowyText.medium(LocaleKeys.grid_field_optionTitle.tr(), fontSize: 12)];
        if (state.options.isNotEmpty) {
          children.add(const Spacer());
          children.add(const _OptionTitleButton());
        }

        return SizedBox(
          height: GridSize.typeOptionItemHeight,
          child: Row(children: children),
        );
      },
    );
  }
}

class _OptionTitleButton extends StatelessWidget {
  const _OptionTitleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      width: 100,
      height: 26,
      child: FlowyButton(
        text: FlowyText.medium(
          LocaleKeys.grid_field_addOption.tr(),
          fontSize: 12,
          textAlign: TextAlign.center,
        ),
        hoverColor: theme.hover,
        onTap: () {
          context.read<SelectOptionTypeOptionBloc>().add(const SelectOptionTypeOptionEvent.addingOption());
        },
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  final TypeOptionOverlayDelegate delegate;
  const _OptionList(this.delegate, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      buildWhen: (previous, current) {
        return previous.options != current.options;
      },
      builder: (context, state) {
        final cells = state.options.map((option) {
          return _makeOptionCell(context, option);
        }).toList();

        return ListView.separated(
          shrinkWrap: true,
          controller: ScrollController(),
          separatorBuilder: (context, index) {
            return VSpace(GridSize.typeOptionSeparatorHeight);
          },
          itemCount: cells.length,
          itemBuilder: (BuildContext context, int index) {
            return cells[index];
          },
        );
      },
    );
  }

  _OptionCell _makeOptionCell(BuildContext context, SelectOptionPB option) {
    return _OptionCell(
      option: option,
      onSelected: (option) {
        final pannel = SelectOptionTypeOptionEditor(
          option: option,
          onDeleted: () {
            delegate.hideOverlay(context);
            context.read<SelectOptionTypeOptionBloc>().add(SelectOptionTypeOptionEvent.deleteOption(option));
          },
          onUpdated: (updatedOption) {
            delegate.hideOverlay(context);
            context.read<SelectOptionTypeOptionBloc>().add(SelectOptionTypeOptionEvent.updateOption(updatedOption));
          },
          key: ValueKey(option.id),
        );
        delegate.showOverlay(context, pannel);
      },
    );
  }
}

class _OptionCell extends StatelessWidget {
  final SelectOptionPB option;
  final Function(SelectOptionPB) onSelected;
  const _OptionCell({
    required this.option,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: SelectOptionTagCell(
        option: option,
        onSelected: onSelected,
        children: [
          svgWidget(
            "grid/details",
            color: theme.iconColor,
          ),
        ],
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
          context.read<SelectOptionTypeOptionBloc>().add(const SelectOptionTypeOptionEvent.addingOption());
        },
        leftIcon: svgWidget("home/add", color: theme.iconColor),
      ),
    );
  }
}

class _CreateOptionTextField extends StatelessWidget {
  const _CreateOptionTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        final text = state.newOptionName.foldRight("", (a, previous) => a);
        return InputTextField(
          autoClearWhenDone: true,
          text: text,
          onCanceled: () {
            context.read<SelectOptionTypeOptionBloc>().add(const SelectOptionTypeOptionEvent.endAddingOption());
          },
          onDone: (optionName) {
            context.read<SelectOptionTypeOptionBloc>().add(SelectOptionTypeOptionEvent.createOption(optionName));
          },
        );
      },
    );
  }
}
