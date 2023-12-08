import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/select_option_type_option_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

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
    super.key,
    required this.options,
    required this.beginEdit,
    required this.typeOptionAction,
    this.popoverMutex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SelectOptionTypeOptionBloc>(
      create: (context) => SelectOptionTypeOptionBloc(
        options: options,
        typeOptionAction: typeOptionAction,
      ),
      child:
          BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
        builder: (context, state) {
          final List<Widget> children = [
            const TypeOptionSeparator(spacing: 8),
            const _OptionTitle(),
            const VSpace(4),
            if (state.isEditingOption) ...[
              CreateOptionTextField(popoverMutex: popoverMutex),
              const VSpace(4),
            ] else
              const _AddOptionButton(),
            const VSpace(4),
            _OptionList(popoverMutex: popoverMutex),
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
        },
      ),
    );
  }
}

class _OptionTitle extends StatelessWidget {
  const _OptionTitle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FlowyText.regular(
              LocaleKeys.grid_field_optionTitle.tr(),
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        );
      },
    );
  }
}

class _OptionList extends StatelessWidget {
  final PopoverMutex? popoverMutex;
  const _OptionList({this.popoverMutex});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      buildWhen: (previous, current) {
        return previous.options != current.options;
      },
      builder: (context, state) {
        final cells = state.options.map((option) {
          return _OptionCell(
            option: option,
            popoverMutex: popoverMutex,
          );
        }).toList();

        return ListView.separated(
          shrinkWrap: true,
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
}

class _OptionCell extends StatefulWidget {
  final SelectOptionPB option;
  final PopoverMutex? popoverMutex;
  const _OptionCell({required this.option, this.popoverMutex});

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
      height: 28,
      child: SelectOptionTagCell(
        option: widget.option,
        onSelected: () => _popoverController.show(),
        children: [
          FlowyIconButton(
            onPressed: () => _popoverController.show(),
            iconPadding: const EdgeInsets.symmetric(horizontal: 6.0),
            hoverColor: Colors.transparent,
            icon: FlowySvg(
              FlowySvgs.details_s,
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
      constraints: BoxConstraints.loose(const Size(460, 470)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
  const _AddOptionButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          text: FlowyText.medium(
            LocaleKeys.grid_field_addSelectOption.tr(),
          ),
          onTap: () {
            context
                .read<SelectOptionTypeOptionBloc>()
                .add(const SelectOptionTypeOptionEvent.addingOption());
          },
          leftIcon: const FlowySvg(FlowySvgs.add_s),
        ),
      ),
    );
  }
}

class CreateOptionTextField extends StatefulWidget {
  final PopoverMutex? popoverMutex;

  const CreateOptionTextField({
    super.key,
    this.popoverMutex,
  });

  @override
  State<CreateOptionTextField> createState() => _CreateOptionTextFieldState();
}

class _CreateOptionTextFieldState extends State<CreateOptionTextField> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: FlowyTextField(
            autoClearWhenDone: true,
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

  @override
  void dispose() {
    _focusNode.removeListener(() {
      if (_focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });
    _focusNode.dispose();
    super.dispose();
  }
}
