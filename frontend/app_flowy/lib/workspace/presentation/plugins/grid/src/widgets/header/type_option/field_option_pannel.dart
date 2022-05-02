import 'package:app_flowy/workspace/application/grid/field/type_option/field_option_pannel_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/common/text_field.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_switcher.dart';
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

import 'edit_option_pannel.dart';

class FieldSelectOptionPannel extends StatelessWidget {
  final List<SelectOption> options;
  final VoidCallback beginEdit;
  final Function(String optionName) createOptionCallback;
  final Function(SelectOption) updateOptionCallback;
  final Function(SelectOption) deleteOptionCallback;
  final TypeOptionOverlayDelegate overlayDelegate;

  const FieldSelectOptionPannel({
    required this.options,
    required this.beginEdit,
    required this.createOptionCallback,
    required this.updateOptionCallback,
    required this.deleteOptionCallback,
    required this.overlayDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldOptionPannelBloc(options: options),
      child: BlocConsumer<FieldOptionPannelBloc, FieldOptionPannelState>(
        listener: (context, state) {
          if (state.isEditingOption) {
            beginEdit();
          }
          state.newOptionName.fold(
            () => null,
            (optionName) => createOptionCallback(optionName),
          );

          state.updateOption.fold(
            () => null,
            (updateOption) => updateOptionCallback(updateOption),
          );

          state.deleteOption.fold(
            () => null,
            (deleteOption) => deleteOptionCallback(deleteOption),
          );
        },
        builder: (context, state) {
          List<Widget> children = [
            const TypeOptionSeparator(),
            const OptionTitle(),
          ];
          if (state.isEditingOption) {
            children.add(const _OptionNameTextField());
          }

          if (state.options.isEmpty && !state.isEditingOption) {
            children.add(const _AddOptionButton());
          }

          if (state.options.isNotEmpty) {
            children.add(_OptionList(overlayDelegate));
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

    return BlocBuilder<FieldOptionPannelBloc, FieldOptionPannelState>(
      builder: (context, state) {
        List<Widget> children = [FlowyText.medium(LocaleKeys.grid_field_optionTitle.tr(), fontSize: 12)];
        if (state.options.isNotEmpty) {
          children.add(const Spacer());
          children.add(
            SizedBox(
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
                  context.read<FieldOptionPannelBloc>().add(const FieldOptionPannelEvent.beginAddingOption());
                },
              ),
            ),
          );
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
  final TypeOptionOverlayDelegate delegate;
  const _OptionList(this.delegate, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldOptionPannelBloc, FieldOptionPannelState>(
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

  _OptionCell _makeOptionCell(BuildContext context, SelectOption option) {
    return _OptionCell(
      option: option,
      onEdited: (option) {
        final pannel = EditSelectOptionPannel(
          option: option,
          onDeleted: () {
            delegate.hideOverlay(context);
            context.read<FieldOptionPannelBloc>().add(FieldOptionPannelEvent.deleteOption(option));
          },
          onUpdated: (updatedOption) {
            delegate.hideOverlay(context);
            context.read<FieldOptionPannelBloc>().add(FieldOptionPannelEvent.updateOption(updatedOption));
          },
          key: ValueKey(option.id),
        );
        delegate.showOverlay(context, pannel);
      },
    );
  }
}

class _OptionCell extends StatelessWidget {
  final SelectOption option;
  final Function(SelectOption) onEdited;
  const _OptionCell({
    required this.option,
    required this.onEdited,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(option.name, fontSize: 12),
        hoverColor: theme.hover,
        onTap: () => onEdited(option),
        rightIcon: svgWidget("grid/details", color: theme.iconColor),
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
          context.read<FieldOptionPannelBloc>().add(const FieldOptionPannelEvent.beginAddingOption());
        },
        leftIcon: svgWidget("home/add", color: theme.iconColor),
      ),
    );
  }
}

class _OptionNameTextField extends StatelessWidget {
  const _OptionNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InputTextField(
      text: "",
      onCanceled: () {
        context.read<FieldOptionPannelBloc>().add(const FieldOptionPannelEvent.endAddingOption());
      },
      onDone: (optionName) {
        context.read<FieldOptionPannelBloc>().add(FieldOptionPannelEvent.createOption(optionName));
      },
    );
  }
}
