import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/base/option_color_list.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
        ),
        child: BlocBuilder<SelectOptionCellEditorBloc,
            SelectOptionCellEditorState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DragHandle(),
                _buildHeader(context),
                const Divider(height: 0.5),
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

  Widget _buildHeader(BuildContext context) {
    const height = 44.0;
    return Stack(
      children: [
        if (showMoreOptions)
          Align(
            alignment: Alignment.centerLeft,
            child: AppBarBackButton(onTap: _popOrBack),
          ),
        SizedBox(
          height: 44.0,
          child: Align(
            child: FlowyText.medium(
              _headerTitle(),
              fontSize: 18,
            ),
          ),
        ),
      ].map((e) => SizedBox(height: height, child: e)).toList(),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (showMoreOptions && option != null) {
      return _MoreOptions(
        initialOption: option!,
        controller: renameController,
        onDelete: () {
          context
              .read<SelectOptionCellEditorBloc>()
              .add(SelectOptionCellEditorEvent.deleteOption(option!));
          _popOrBack();
        },
        onUpdate: (name, color) {
          final option = this.option;
          if (option == null) {
            return;
          }
          option.freeze();
          context.read<SelectOptionCellEditorBloc>().add(
            SelectOptionCellEditorEvent.updateOption(
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
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const VSpace(16),
          _SearchField(
            controller: searchController,
            hintText: LocaleKeys.grid_selectOption_searchOrCreateOption.tr(),
            onSubmitted: (_) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(const SelectOptionCellEditorEvent.submitTextField());
              searchController.clear();
            },
            onChanged: (value) {
              typingOption = value;
              context.read<SelectOptionCellEditorBloc>().add(
                    SelectOptionCellEditorEvent.selectMultipleOptions(
                      [],
                      value,
                    ),
                  );
            },
          ),
          const VSpace(22),
          _OptionList(
            fieldType: widget.cellController.fieldType,
            onCreateOption: (optionName) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(const SelectOptionCellEditorEvent.createOption());
              searchController.clear();
            },
            onCheck: (option, value) {
              if (value) {
                context
                    .read<SelectOptionCellEditorBloc>()
                    .add(SelectOptionCellEditorEvent.selectOption(option.id));
              } else {
                context
                    .read<SelectOptionCellEditorBloc>()
                    .add(SelectOptionCellEditorEvent.unselectOption(option.id));
              }
            },
            onMoreOptions: (option) {
              setState(() {
                this.option = option;
                renameController.text = option.name;
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
    return FlowyMobileSearchTextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      hintText: hintText,
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.fieldType,
    required this.onCreateOption,
    required this.onCheck,
    required this.onMoreOptions,
  });

  final FieldType fieldType;
  final void Function(String optionName) onCreateOption;
  final void Function(SelectOptionPB option, bool value) onCheck;
  final void Function(SelectOptionPB option) onMoreOptions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionCellEditorState>(
      builder: (context, state) {
        // existing options
        final List<Widget> cells = [];

        // create an option cell
        if (state.createSelectOptionSuggestion != null) {
          cells.add(
            _CreateOptionCell(
              name: state.createSelectOptionSuggestion!.name,
              color: state.createSelectOptionSuggestion!.color,
              onTap: () => onCreateOption(
                state.createSelectOptionSuggestion!.name,
              ),
            ),
          );
        }

        cells.addAll(
          state.options.map(
            (option) => _SelectOption(
              fieldType: fieldType,
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
          separatorBuilder: (_, __) => const VSpace(20),
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
    required this.fieldType,
    required this.option,
    required this.checked,
    required this.onCheck,
    required this.onMoreOptions,
  });

  final FieldType fieldType;
  final SelectOptionPB option;
  final bool checked;
  final void Function(bool value) onCheck;
  final VoidCallback onMoreOptions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: GestureDetector(
        // no need to add click effect, so using gesture detector
        behavior: HitTestBehavior.translucent,
        onTap: () => onCheck(!checked),
        child: Row(
          children: [
            // checked or selected icon
            SizedBox(
              height: 20,
              width: 20,
              child: _IsSelectedIndicator(
                fieldType: fieldType,
                isSelected: checked,
              ),
            ),
            // padding
            const HSpace(12),
            // option tag
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SelectOptionTag(
                  option: option,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  textAlign: TextAlign.center,
                  fontSize: 15.0,
                ),
              ),
            ),
            const HSpace(24),
            // more options
            FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.m_field_more_s,
              ),
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
    required this.name,
    required this.color,
    required this.onTap,
  });

  final String name;
  final SelectOptionColorPB color;
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
                alignment: AlignmentDirectional.centerStart,
                child: SelectOptionTag(
                  name: name,
                  color: color.toColor(context),
                  textAlign: TextAlign.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreOptions extends StatefulWidget {
  const _MoreOptions({
    required this.initialOption,
    required this.onDelete,
    required this.onUpdate,
    required this.controller,
  });

  final SelectOptionPB initialOption;
  final VoidCallback onDelete;
  final void Function(String? name, SelectOptionColorPB? color) onUpdate;
  final TextEditingController controller;

  @override
  State<_MoreOptions> createState() => _MoreOptionsState();
}

class _MoreOptionsState extends State<_MoreOptions> {
  late SelectOptionPB option = widget.initialOption;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRenameTextField(context),
          const VSpace(16.0),
          _buildDeleteButton(context),
          const VSpace(16.0),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: FlowyText(
              LocaleKeys.grid_selectOption_colorPanelTitle.tr().toUpperCase(),
              color: Theme.of(context).hintColor,
              fontSize: 13,
            ),
          ),
          const VSpace(4.0),
          FlowyOptionDecorateBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 6.0,
              ),
              child: OptionColorList(
                selectedColor: option.color,
                onSelectedColor: (color) {
                  widget.onUpdate(null, color);
                  setState(() {
                    option.freeze();
                    option = option.rebuild((option) => option.color = color);
                  });
                },
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
        showTopBorder: false,
        onTextChanged: (name) => widget.onUpdate(name, null),
        controller: widget.controller,
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.button_delete.tr(),
      textColor: Theme.of(context).colorScheme.error,
      leftIcon: FlowySvg(
        FlowySvgs.m_delete_s,
        color: Theme.of(context).colorScheme.error,
      ),
      onTap: widget.onDelete,
    );
  }
}

class _IsSelectedIndicator extends StatelessWidget {
  const _IsSelectedIndicator({
    required this.fieldType,
    required this.isSelected,
  });

  final FieldType fieldType;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return isSelected
        ? DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: fieldType == FieldType.MultiSelect
                  ? FlowySvg(
                      FlowySvgs.checkmark_tiny_s,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          );
  }
}
