import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/edit_select_option_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../../../grid/presentation/widgets/common/type_option_separator.dart';

class SelectOptionEditor extends StatelessWidget {
  const SelectOptionEditor({
    super.key,
    required this.option,
    required this.onDeleted,
    required this.onUpdated,
    this.showOptions = true,
    this.autoFocus = true,
  });

  final SelectOptionPB option;
  final VoidCallback onDeleted;
  final Function(SelectOptionPB) onUpdated;
  final bool showOptions;
  final bool autoFocus;

  static String get identifier => (SelectOptionEditor).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditSelectOptionBloc(option: option),
      child: MultiBlocListener(
        listeners: [
          BlocListener<EditSelectOptionBloc, EditSelectOptionState>(
            listenWhen: (p, c) => p.deleted != c.deleted,
            listener: (context, state) {
              if (state.deleted) {
                onDeleted();
              }
            },
          ),
          BlocListener<EditSelectOptionBloc, EditSelectOptionState>(
            listenWhen: (p, c) => p.option != c.option,
            listener: (context, state) {
              onUpdated(state.option);
            },
          ),
        ],
        child: BlocBuilder<EditSelectOptionBloc, EditSelectOptionState>(
          builder: (context, state) {
            final List<Widget> cells = [
              _OptionNameTextField(
                name: state.option.name,
                autoFocus: autoFocus,
              ),
              const VSpace(10),
              const _DeleteTag(),
              const TypeOptionSeparator(),
              SelectOptionColorList(
                selectedColor: state.option.color,
                onSelectedColor: (color) => context
                    .read<EditSelectOptionBloc>()
                    .add(EditSelectOptionEvent.updateColor(color)),
              ),
            ];
            return SizedBox(
              width: 180,
              child: ListView.builder(
                shrinkWrap: true,
                physics: StyledScrollPhysics(),
                itemCount: cells.length,
                itemBuilder: (context, index) {
                  if (cells[index] is TypeOptionSeparator) {
                    return cells[index];
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: cells[index],
                    );
                  }
                },
                padding: const EdgeInsets.symmetric(vertical: 6.0),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeleteTag extends StatelessWidget {
  const _DeleteTag();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText(
          lineHeight: 1.0,
          LocaleKeys.grid_selectOption_deleteTag.tr(),
        ),
        leftIcon: const FlowySvg(FlowySvgs.delete_s),
        onTap: () {
          context
              .read<EditSelectOptionBloc>()
              .add(const EditSelectOptionEvent.delete());
        },
      ),
    );
  }
}

class _OptionNameTextField extends StatelessWidget {
  const _OptionNameTextField({
    required this.name,
    required this.autoFocus,
  });

  final String name;
  final bool autoFocus;

  @override
  Widget build(BuildContext context) {
    return FlowyTextField(
      autoFocus: autoFocus,
      text: name,
      submitOnLeave: true,
      onSubmitted: (newName) {
        if (name != newName) {
          context
              .read<EditSelectOptionBloc>()
              .add(EditSelectOptionEvent.updateName(newName));
        }
      },
    );
  }
}

class SelectOptionColorList extends StatelessWidget {
  const SelectOptionColorList({
    super.key,
    this.selectedColor,
    required this.onSelectedColor,
  });

  final SelectOptionColorPB? selectedColor;
  final void Function(SelectOptionColorPB color) onSelectedColor;

  @override
  Widget build(BuildContext context) {
    final cells = SelectOptionColorPB.values.map((color) {
      return _SelectOptionColorCell(
        color: color,
        isSelected: selectedColor != null ? selectedColor == color : false,
        onSelectedColor: onSelectedColor,
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: GridSize.typeOptionContentInsets,
          child: SizedBox(
            height: GridSize.popoverItemHeight,
            child: FlowyText(
              LocaleKeys.grid_selectOption_colorPanelTitle.tr(),
              textAlign: TextAlign.left,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
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
  const _SelectOptionColorCell({
    required this.color,
    required this.isSelected,
    required this.onSelectedColor,
  });

  final SelectOptionColorPB color;
  final bool isSelected;
  final void Function(SelectOptionColorPB color) onSelectedColor;

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = const FlowySvg(FlowySvgs.check_s);
    }

    final colorIcon = SizedBox.square(
      dimension: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.toColor(context),
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText(
          lineHeight: 1.0,
          color.colorName(),
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: colorIcon,
        rightIcon: checkmark,
        onTap: () => onSelectedColor(color),
      ),
    );
  }
}
