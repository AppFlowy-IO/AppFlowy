import 'package:app_flowy/plugins/grid/application/field/type_option/edit_select_option_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import '../../../layout/sizes.dart';
import '../../common/type_option_separator.dart';

class SelectOptionTypeOptionEditor extends StatelessWidget {
  final SelectOptionPB option;
  final VoidCallback onDeleted;
  final Function(SelectOptionPB) onUpdated;
  final bool showOptions;
  final bool autoFocus;
  const SelectOptionTypeOptionEditor({
    required this.option,
    required this.onDeleted,
    required this.onUpdated,
    this.showOptions = true,
    this.autoFocus = true,
    Key? key,
  }) : super(key: key);

  static String get identifier => (SelectOptionTypeOptionEditor).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditSelectOptionBloc(option: option),
      child: MultiBlocListener(
        listeners: [
          BlocListener<EditSelectOptionBloc, EditSelectOptionState>(
            listenWhen: (p, c) => p.deleted != c.deleted,
            listener: (context, state) {
              state.deleted.fold(() => null, (_) => onDeleted());
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
            List<Widget> cells = [
              _OptionNameTextField(
                name: state.option.name,
                autoFocus: autoFocus,
              ),
              const VSpace(10),
              const _DeleteTag(),
            ];

            if (showOptions) {
              cells.add(const TypeOptionSeparator());
              cells.add(
                  SelectOptionColorList(selectedColor: state.option.color));
            }

            return SizedBox(
              width: 180,
              child: ListView.builder(
                shrinkWrap: true,
                controller: ScrollController(),
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
  const _DeleteTag({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_selectOption_deleteTag.tr()),
        leftIcon: svgWidget(
          "grid/delete",
          color: Theme.of(context).colorScheme.onSurface,
        ),
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
  final String name;
  final bool autoFocus;
  const _OptionNameTextField(
      {required this.name, required this.autoFocus, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyTextField(
      autoFocus: autoFocus,
      text: name,
      maxLength: 30,
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
  final SelectOptionColorPB selectedColor;
  const SelectOptionColorList({required this.selectedColor, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = SelectOptionColorPB.values.map((color) {
      return _SelectOptionColorCell(
          color: color, isSelected: selectedColor == color);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: GridSize.typeOptionContentInsets,
          child: SizedBox(
            height: GridSize.popoverItemHeight,
            child: FlowyText.medium(
              LocaleKeys.grid_selectOption_colorPanelTitle.tr(),
              textAlign: TextAlign.left,
              color: Theme.of(context).hintColor,
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
  final SelectOptionColorPB color;
  final bool isSelected;
  const _SelectOptionColorCell(
      {required this.color, required this.isSelected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    final colorIcon = SizedBox.square(
      dimension: 16,
      child: Container(
        decoration: BoxDecoration(
          color: color.make(context),
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(color.optionName()),
        leftIcon: colorIcon,
        rightIcon: checkmark,
        onTap: () {
          context
              .read<EditSelectOptionBloc>()
              .add(EditSelectOptionEvent.updateColor(color));
        },
      ),
    );
  }
}
