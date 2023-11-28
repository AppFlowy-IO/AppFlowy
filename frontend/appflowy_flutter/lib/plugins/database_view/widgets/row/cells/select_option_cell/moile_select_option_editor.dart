import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectOptionCellEditorBloc(
        cellController: widget.cellController,
      )..add(const SelectOptionEditorEvent.initial()),
      child: Column(
        children: [
          _SearchField(
            hintText: LocaleKeys.grid_selectOption_searchOrCreateOption.tr(),
          ),
          const _OptionList(),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
  });

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: SizedBox(
        height: 44, // the height is fixed.
        child: FlowyTextField(
          hintText: hintText,
        ),
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      builder: (context, state) {
        // existing options
        final List<Widget> cells = state.options
            .map(
              (option) => _SelectOption(
                option: option,
                checked: state.selectedOptions.contains(option),
                onCheck: (value) => context
                    .read<SelectOptionCellEditorBloc>()
                    .add(SelectOptionEditorEvent.updateOption(option)),
              ),
            )
            .toList();

        // create an option cell
        state.createOption.fold(
          () => null,
          (createOption) {
            cells.add(_CreateOptionCell(optionName: createOption));
          },
        );

        return ListView.separated(
          shrinkWrap: true,
          itemCount: cells.length,
          separatorBuilder: (_, __) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          physics: StyledScrollPhysics(),
          itemBuilder: (_, int index) => cells[index],
          padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
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
      child: FlowyButton(
        onTap: () => onCheck(!checked),
        text: Row(
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
            const FlowyIconButton(
              icon: FlowySvg(FlowySvgs.three_dots_s),
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
      height: 34,
      child: FlowyButton(
        onTap: () => context
            .read<SelectOptionCellEditorBloc>()
            .add(SelectOptionEditorEvent.newOption(optionName)),
        text: Row(
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
                  color: Theme.of(context).colorScheme.background,
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
