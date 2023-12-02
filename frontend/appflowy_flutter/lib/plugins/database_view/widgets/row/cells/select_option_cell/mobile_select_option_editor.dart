import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/option_color_list.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:protobuf/protobuf.dart';

// include single select and multiple select
class MobileSelectOptionEditor extends StatefulWidget {
  const MobileSelectOptionEditor({
    super.key,
    required this.cellController,
  });

  final SelectOptionCellController cellController;

  @override
  State<MobileSelectOptionEditor> createState() =>
      _MobileSelectOptionEditorState();
}

class _MobileSelectOptionEditorState extends State<MobileSelectOptionEditor> {
  final searchController = TextEditingController();
  final renameController = TextEditingController();

  String typingOption = '';
  FieldType get fieldType => widget.cellController.fieldType;

  bool showMoreOptions = false;
  SelectOptionPB? option;

  @override
  void dispose() {
    searchController.dispose();
    renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(height: 420),
      child: BlocProvider(
        create: (context) => SelectOptionCellEditorBloc(
          cellController: widget.cellController,
        )..add(const SelectOptionEditorEvent.initial()),
        child: BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DragHandler(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildHeader(
                    context,
                    showSaveButton: state.createOption
                            .fold(() => false, (a) => a.isNotEmpty) ||
                        showMoreOptions,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: showMoreOptions ? 0.0 : 16.0,
                    ),
                    child: _buildBody(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool showSaveButton}) {
    const iconWidth = 36.0;
    const height = 44.0;
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FlowyIconButton(
            icon: const FlowySvg(
              FlowySvgs.close_s,
              size: Size.square(iconWidth),
            ),
            width: iconWidth,
            iconPadding: EdgeInsets.zero,
            onPressed: () => _popOrBack(),
          ),
        ),
        SizedBox(
          height: 44.0,
          child: Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              _headerTitle(),
              fontSize: 18,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: !showSaveButton
              ? const HSpace(iconWidth)
              : Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 8.0,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00bcf0),
                    borderRadius: Corners.s10Border,
                  ),
                  child: FlowyButton(
                    text: FlowyText(
                      LocaleKeys.button_save.tr(),
                      color: Colors.white,
                    ),
                    useIntrinsicWidth: true,
                    onTap: () {
                      if (showMoreOptions) {
                        final option = this.option;
                        if (option == null) {
                          return;
                        }
                        option.freeze();
                        context.read<SelectOptionCellEditorBloc>().add(
                          SelectOptionEditorEvent.updateOption(
                            option.rebuild((p0) {
                              if (p0.name != renameController.text) {
                                p0.name = renameController.text;
                              }
                            }),
                          ),
                        );
                        _popOrBack();
                      } else if (typingOption.isNotEmpty) {
                        context.read<SelectOptionCellEditorBloc>().add(
                              SelectOptionEditorEvent.trySelectOption(
                                typingOption,
                              ),
                            );
                        searchController.clear();
                      }
                    },
                  ),
                ),
        ),
      ].map((e) => SizedBox(height: height, child: e)).toList(),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (showMoreOptions && option != null) {
      return _MoreOptions(
        option: option!,
        controller: renameController..text = option!.name,
        onDelete: () {
          context
              .read<SelectOptionCellEditorBloc>()
              .add(SelectOptionEditorEvent.deleteOption(option!));
          context.pop();
        },
        onUpdate: (name, color) {
          final option = this.option;
          if (option == null) {
            return;
          }
          option.freeze();
          context.read<SelectOptionCellEditorBloc>().add(
            SelectOptionEditorEvent.updateOption(
              option.rebuild((p0) {
                if (name != null) {
                  p0.name = name;
                }
                if (color != null) {
                  p0.color = color;
                }
              }),
            ),
          );
          _popOrBack();
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _SearchField(
            controller: searchController,
            hintText: LocaleKeys.grid_selectOption_searchOrCreateOption.tr(),
            onSubmitted: (option) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(SelectOptionEditorEvent.trySelectOption(option));
              searchController.clear();
            },
            onChanged: (value) {
              typingOption = value;
              context.read<SelectOptionCellEditorBloc>().add(
                    SelectOptionEditorEvent.selectMultipleOptions(
                      [],
                      value,
                    ),
                  );
            },
          ),
          _OptionList(
            onCreateOption: (optionName) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(SelectOptionEditorEvent.newOption(optionName));
              searchController.clear();
            },
            onCheck: (option, value) {
              if (value) {
                context
                    .read<SelectOptionCellEditorBloc>()
                    .add(SelectOptionEditorEvent.selectOption(option.id));
              } else {
                context
                    .read<SelectOptionCellEditorBloc>()
                    .add(SelectOptionEditorEvent.unSelectOption(option.id));
              }
            },
            onMoreOptions: (option) {
              setState(() {
                this.option = option;
                showMoreOptions = true;
              });
            },
          ),
        ],
      ),
    );
  }

  String _headerTitle() {
    switch (fieldType) {
      case FieldType.SingleSelect:
        return LocaleKeys.grid_field_singleSelectFieldName.tr();
      case FieldType.MultiSelect:
        return LocaleKeys.grid_field_multiSelectFieldName.tr();
      default:
        throw UnimplementedError();
    }
  }

  void _popOrBack() {
    if (showMoreOptions) {
      setState(() {
        showMoreOptions = false;
        option = null;
      });
    } else {
      context.pop();
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.controller,
  });

  final String? hintText;
  final void Function(String value) onChanged;
  final void Function(String value) onSubmitted;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: SizedBox(
        height: 44, // the height is fixed.
        child: FlowyTextField(
          autoFocus: false,
          hintText: hintText,
          textStyle: textStyle,
          hintStyle: textStyle?.copyWith(color: Theme.of(context).hintColor),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          controller: controller,
        ),
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.onCreateOption,
    required this.onCheck,
    required this.onMoreOptions,
  });

  final void Function(String optionName) onCreateOption;
  final void Function(SelectOptionPB option, bool value) onCheck;
  final void Function(SelectOptionPB option) onMoreOptions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        // existing options
        final List<Widget> cells = [];

        // create an option cell
        state.createOption.fold(
          () => null,
          (createOption) {
            cells.add(
              _CreateOptionCell(
                optionName: createOption,
                onTap: () => onCreateOption(createOption),
              ),
            );
          },
        );

        cells.addAll(
          state.options.map(
            (option) => _SelectOption(
              option: option,
              checked: state.selectedOptions.contains(option),
              onCheck: (value) => onCheck(option, value),
              onMoreOptions: () => onMoreOptions(option),
            ),
          ),
        );

        return ListView.separated(
          shrinkWrap: true,
          itemCount: cells.length,
          separatorBuilder: (_, __) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, int index) => cells[index],
          padding: const EdgeInsets.only(bottom: 12.0),
        );
      },
    );
  }
}

class _SelectOption extends StatelessWidget {
  const _SelectOption({
    required this.option,
    required this.checked,
    required this.onCheck,
    required this.onMoreOptions,
  });

  final SelectOptionPB option;
  final bool checked;
  final void Function(bool value) onCheck;
  final VoidCallback onMoreOptions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: GestureDetector(
        // no need to add click effect, so using gesture detector
        behavior: HitTestBehavior.translucent,
        onTap: () => onCheck(!checked),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // check icon
            FlowySvg(
              checked
                  ? FlowySvgs.m_checkbox_checked_s
                  : FlowySvgs.m_checkbox_uncheck_s,
              size: const Size.square(24.0),
              blendMode: null,
            ),
            // padding
            const HSpace(12),
            // option tag
            SelectOptionTag(
              option: option,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            ),
            const Spacer(),
            // more options
            FlowyIconButton(
              icon: const FlowySvg(FlowySvgs.three_dots_s),
              onPressed: onMoreOptions,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOptionCell extends StatelessWidget {
  const _CreateOptionCell({
    required this.optionName,
    required this.onTap,
  });

  final String optionName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Row(
          children: [
            FlowyText.medium(
              LocaleKeys.grid_selectOption_create.tr(),
              color: Theme.of(context).hintColor,
            ),
            const HSpace(8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SelectOptionTag(
                  name: optionName,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreOptions extends StatelessWidget {
  const _MoreOptions({
    required this.option,
    required this.onDelete,
    required this.onUpdate,
    required this.controller,
  });

  final SelectOptionPB option;
  final VoidCallback onDelete;
  final void Function(String? name, SelectOptionColorPB? color) onUpdate;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondaryContainer;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSpace(8.0),
          _buildRenameTextField(context),
          const VSpace(16.0),
          _buildDeleteButton(context),
          const VSpace(16.0),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ColoredBox(
              color: color,
              child: FlowyText(
                LocaleKeys.grid_field_optionTitle.tr(),
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const VSpace(4.0),
          FlowyOptionDecorateBox(
            showTopBorder: true,
            showBottomBorder: true,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 6.0,
                right: 6.0,
              ),
              child: OptionColorList(
                selectedColor: option.color,
                onSelectedColor: (color) => onUpdate(null, color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenameTextField(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(height: 52.0),
      child: FlowyOptionTile.textField(
        controller: controller,
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.button_delete.tr(),
      leftIcon: const FlowySvg(FlowySvgs.delete_s),
      onTap: onDelete,
    );
  }
}
