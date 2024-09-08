import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/select_option_type_option_bloc.dart';
import 'package:appflowy/plugins/database/application/field/type_option/select_type_option_actions.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'select_option_editor.dart';

class SelectOptionTypeOptionWidget extends StatelessWidget {
  const SelectOptionTypeOptionWidget({
    super.key,
    required this.options,
    required this.beginEdit,
    required this.typeOptionAction,
    this.popoverMutex,
  });

  final List<SelectOptionPB> options;
  final VoidCallback beginEdit;
  final ISelectOptionAction typeOptionAction;
  final PopoverMutex? popoverMutex;

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
            const _OptionTitle(),
            const VSpace(4),
            if (state.isEditingOption) ...[
              CreateOptionTextField(popoverMutex: popoverMutex),
              const VSpace(4),
            ] else
              const _AddOptionButton(),
            const VSpace(4),
            Flexible(
              child: _OptionList(
                popoverMutex: popoverMutex,
              ),
            ),
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

class _OptionCell extends StatefulWidget {
  const _OptionCell({
    super.key,
    required this.option,
    required this.index,
    this.popoverMutex,
  });

  final SelectOptionPB option;
  final int index;
  final PopoverMutex? popoverMutex;

  @override
  State<_OptionCell> createState() => _OptionCellState();
}

class _OptionCellState extends State<_OptionCell> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 28,
      child: SelectOptionTagCell(
        option: widget.option,
        index: widget.index,
        onSelected: () => _popoverController.show(),
        children: [
          FlowyIconButton(
            onPressed: () => _popoverController.show(),
            iconPadding: const EdgeInsets.symmetric(horizontal: 6.0),
            hoverColor: Colors.transparent,
            icon: FlowySvg(
              FlowySvgs.three_dots_s,
              color: Theme.of(context).iconTheme.color,
              size: const Size.square(16),
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
        child: FlowyHover(
          resetHoverOnRebuild: false,
          style: HoverStyle(
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
          ),
          child: child,
        ),
      ),
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionEditor(
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
            lineHeight: 1.0,
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
  const CreateOptionTextField({super.key, this.popoverMutex});

  final PopoverMutex? popoverMutex;

  @override
  State<CreateOptionTextField> createState() => _CreateOptionTextFieldState();
}

class _CreateOptionTextFieldState extends State<CreateOptionTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (_focusNode.hasFocus) {
          widget.popoverMutex?.close();
        }
      });
    widget.popoverMutex?.listenOnPopoverChanged(() {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        final text = state.newOptionName ?? '';
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

class _OptionList extends StatelessWidget {
  const _OptionList({
    this.popoverMutex,
  });

  final PopoverMutex? popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionTypeOptionBloc, SelectOptionTypeOptionState>(
      builder: (context, state) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          onReorderStart: (_) => popoverMutex?.close(),
          proxyDecorator: (child, index, _) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                BlocProvider.value(
                  value: context.read<SelectOptionTypeOptionBloc>(),
                  child: child,
                ),
                MouseRegion(
                  cursor: Platform.isWindows
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.grabbing,
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
          buildDefaultDragHandles: false,
          itemBuilder: (context, index) => _OptionCell(
            key: ValueKey("select_type_option_list_${state.options[index].id}"),
            index: index,
            option: state.options[index],
            popoverMutex: popoverMutex,
          ),
          itemCount: state.options.length,
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex--;
            }
            final fromOptionId = state.options[oldIndex].id;
            final toOptionId = state.options[newIndex].id;
            context.read<SelectOptionTypeOptionBloc>().add(
                  SelectOptionTypeOptionEvent.reorderOption(
                    fromOptionId,
                    toOptionId,
                  ),
                );
          },
        );
      },
    );
  }
}
