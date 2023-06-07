import 'package:appflowy/plugins/database_view/application/field/type_option/select_option_type_option_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import '../../../layout/sizes.dart';
import '../../../../../widgets/row/cells/select_option_cell/extension.dart';
import '../../common/type_option_separator.dart';
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
          final List<Widget> children = [
            const TypeOptionSeparator(),
            const OptionTitle(),
            if (state.isEditingOption)
              _CreateOptionTextField(popoverMutex: popoverMutex),
            if (state.options.isNotEmpty && state.isEditingOption)
              const VSpace(10),
            if (state.options.isEmpty && !state.isEditingOption)
              const _AddOptionButton(),
            _OptionList(popoverMutex: popoverMutex)
          ];

          return ListView.builder(
            shrinkWrap: true,
            itemCount: children.length,
            itemBuilder: (context, index) {
              return children[index];
            },
          );
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
        final List<Widget> children = [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: FlowyText.medium(
              LocaleKeys.grid_field_optionTitle.tr(),
            ),
          )
        ];
        if (state.options.isNotEmpty && !state.isEditingOption) {
          children.add(const Spacer());
          children.add(const _OptionTitleButton());
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SizedBox(
            height: GridSize.popoverItemHeight,
            child: Row(children: children),
          ),
        );
      },
    );
  }
}

class _OptionTitleButton extends StatelessWidget {
  const _OptionTitleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 26,
      child: FlowyButton(
        text: FlowyText.medium(
          LocaleKeys.grid_field_addOption.tr(),
          textAlign: TextAlign.center,
        ),
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
    final child = SizedBox(
      height: GridSize.popoverItemHeight,
      child: SelectOptionTagCell(
        option: widget.option,
        onSelected: (SelectOptionPB pb) {
          _popoverController.show();
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: svgWidget(
              "grid/details",
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
    );
    return AppFlowyPopover(
      controller: _popoverController,
      mutex: widget.popoverMutex,
      offset: const Offset(8, 0),
      margin: EdgeInsets.zero,
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(460, 460)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: child,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText.medium(
            LocaleKeys.grid_field_addSelectOption.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          onTap: () {
            context
                .read<SelectOptionTypeOptionBloc>()
                .add(const SelectOptionTypeOptionEvent.addingOption());
          },
          leftIcon: svgWidget(
            "home/add",
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}

class _CreateOptionTextField extends StatefulWidget {
  final PopoverMutex? popoverMutex;
  const _CreateOptionTextField({
    Key? key,
    this.popoverMutex,
  }) : super(key: key);

  @override
  State<_CreateOptionTextField> createState() => _CreateOptionTextFieldState();
}

class _CreateOptionTextFieldState extends State<_CreateOptionTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });
    widget.popoverMutex?.listenOnPopoverChanged(() {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        final text = state.newOptionName.foldRight("", (a, previous) => a);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: FlowyTextField(
            autoClearWhenDone: true,
            maxLength: 30,
            text: text,
            focusNode: _focusNode,
            onCanceled: () {
              context
                  .read<SelectOptionTypeOptionBloc>()
                  .add(const SelectOptionTypeOptionEvent.endAddingOption());
            },
            onEditingComplete: () {},
            onSubmitted: (optionName) {
              context
                  .read<SelectOptionTypeOptionBloc>()
                  .add(SelectOptionTypeOptionEvent.createOption(optionName));
            },
          ),
        );
      },
    );
  }
}
