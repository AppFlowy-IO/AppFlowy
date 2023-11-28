import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  final controller = TextEditingController();

  String typingOption = '';
  FieldType get fieldType => widget.cellController.fieldType;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(height: 360),
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
                        .fold(() => false, (a) => a.isNotEmpty),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            onPressed: () {
              context.pop();
            },
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
                      if (typingOption.isNotEmpty) {
                        context.read<SelectOptionCellEditorBloc>().add(
                              SelectOptionEditorEvent.trySelectOption(
                                typingOption,
                              ),
                            );
                        controller.clear();
                      }
                    },
                  ),
                ),
        ),
      ].map((e) => SizedBox(height: height, child: e)).toList(),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _SearchField(
            controller: controller,
            hintText: LocaleKeys.grid_selectOption_searchOrCreateOption.tr(),
            onSubmitted: (option) {
              context
                  .read<SelectOptionCellEditorBloc>()
                  .add(SelectOptionEditorEvent.trySelectOption(option));
              controller.clear();
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
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.controller,
  });

  final String hintText;
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
    required this.onCheck,
  });

  final void Function(SelectOptionPB option, bool value) onCheck;

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
            cells.add(_CreateOptionCell(optionName: createOption));
          },
        );

        cells.addAll(
          state.options.map(
            (option) => _SelectOption(
              option: option,
              checked: state.selectedOptions.contains(option),
              onCheck: (value) => onCheck(option, value),
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
  });

  final SelectOptionPB option;
  final bool checked;
  final void Function(bool value) onCheck;

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
            _SelectOptionTag(
              optionName: option.name,
              color: option.color.toColor(context),
            ),
            const Spacer(),
            // more options
            FlowyIconButton(
              icon: const FlowySvg(FlowySvgs.three_dots_s),
              onPressed: () {},
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
  });

  final String optionName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => context
            .read<SelectOptionCellEditorBloc>()
            .add(SelectOptionEditorEvent.newOption(optionName)),
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
                child: _SelectOptionTag(
                  optionName: optionName,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectOptionTag extends StatelessWidget {
  const _SelectOptionTag({
    required this.optionName,
    required this.color,
  });

  final String optionName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
        horizontal: 12.0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: Corners.s12Border,
      ),
      child: FlowyText.regular(
        optionName,
        fontSize: 16,
        overflow: TextOverflow.ellipsis,
        color: AFThemeExtension.of(context).textColor,
      ),
    );
  }
}
