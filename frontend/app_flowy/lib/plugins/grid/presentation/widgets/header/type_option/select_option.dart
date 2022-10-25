import 'package:app_flowy/plugins/grid/application/field/type_option/select_option_type_option_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import '../../../layout/sizes.dart';
import '../../cell/select_option_cell/extension.dart';
import '../../common/text_field.dart';
import 'select_option_editor.dart';

class SelectOptionTypeOptionWidget extends StatelessWidget {
  final List<SelectOptionPB> options;
  final VoidCallback beginEdit;
  final ISelectOptionAction typeOptionAction;
  final PopoverMutex? popoverMutex;

  const SelectOptionTypeOptionWidget({
    required this.options,
    required this.beginEdit,
    required this.typeOptionAction,
    this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionTypeOptionBloc(
        options: options,
        typeOptionAction: typeOptionAction,
      ),
      child:
          BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
        builder: (context, state) {
          List<Widget> children = [
            const TypeOptionSeparator(),
            const OptionTitle(),
            if (state.isEditingOption)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _CreateOptionTextField(),
              ),
            if (state.options.isEmpty && !state.isEditingOption)
              const _AddOptionButton(),
            _OptionList(popoverMutex: popoverMutex)
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
    final theme = context.read<AppTheme>();
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        List<Widget> children = [
          FlowyText.medium(
            LocaleKeys.grid_field_optionTitle.tr(),
            fontSize: 12,
            color: theme.shader3,
          )
        ];
        if (state.options.isNotEmpty && !state.isEditingOption) {
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
          context
              .read<SelectOptionTypeOptionBloc>()
              .add(const SelectOptionTypeOptionEvent.addingOption());
        },
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  final PopoverMutex? popoverMutex;
  const _OptionList({Key? key, this.popoverMutex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      buildWhen: (previous, current) {
        return previous.options != current.options;
      },
      builder: (context, state) {
        final cells = state.options.map((option) {
          return _makeOptionCell(
            context: context,
            option: option,
            popoverMutex: popoverMutex,
          );
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

  _OptionCell _makeOptionCell({
    required BuildContext context,
    required SelectOptionPB option,
    PopoverMutex? popoverMutex,
  }) {
    return _OptionCell(
      option: option,
      popoverMutex: popoverMutex,
    );
  }
}

class _OptionCell extends StatefulWidget {
  final SelectOptionPB option;
  final PopoverMutex? popoverMutex;
  const _OptionCell({required this.option, Key? key, this.popoverMutex})
      : super(key: key);

  @override
  State<_OptionCell> createState() => _OptionCellState();
}

class _OptionCellState extends State<_OptionCell> {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return AppFlowyPopover(
      controller: _popoverController,
      mutex: widget.popoverMutex,
      offset: const Offset(20, 0),
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(460, 440)),
      child: SizedBox(
        height: GridSize.typeOptionItemHeight,
        child: SelectOptionTagCell(
          option: widget.option,
          onSelected: (SelectOptionPB pb) {
            _popoverController.show();
          },
          children: [
            svgWidget(
              "grid/details",
              color: theme.iconColor,
            ),
          ],
        ),
      ),
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionTypeOptionEditor(
          option: widget.option,
          onDeleted: () {
            context
                .read<SelectOptionTypeOptionBloc>()
                .add(SelectOptionTypeOptionEvent.deleteOption(widget.option));
            PopoverContainer.of(popoverContext).close();
          },
          onUpdated: (updatedOption) {
            context
                .read<SelectOptionTypeOptionBloc>()
                .add(SelectOptionTypeOptionEvent.updateOption(updatedOption));
            PopoverContainer.of(popoverContext).close();
          },
          key: ValueKey(widget.option.id),
        );
      },
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
        text: FlowyText.medium(LocaleKeys.grid_field_addSelectOption.tr(),
            fontSize: 12),
        hoverColor: theme.hover,
        onTap: () {
          context
              .read<SelectOptionTypeOptionBloc>()
              .add(const SelectOptionTypeOptionEvent.addingOption());
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
          maxLength: 30,
          text: text,
          onCanceled: () {
            context
                .read<SelectOptionTypeOptionBloc>()
                .add(const SelectOptionTypeOptionEvent.endAddingOption());
          },
          onDone: (optionName) {
            context
                .read<SelectOptionTypeOptionBloc>()
                .add(SelectOptionTypeOptionEvent.createOption(optionName));
          },
        );
      },
    );
  }
}
