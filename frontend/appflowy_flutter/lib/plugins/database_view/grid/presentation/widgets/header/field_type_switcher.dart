import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_type_extension.dart';

class SwitchFieldButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const SwitchFieldButton({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(460, 540)),
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.click,
      mutex: popoverMutex,
      offset: const Offset(8, 0),
      popupBuilder: (popOverContext) {
        return FieldTypeList(
          onSelectField: (newFieldType) {
            context
                .read<FieldEditorBloc>()
                .add(FieldEditorEvent.switchToField(newFieldType));
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: _buildMoreButton(context),
      ),
    );

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: widget,
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final bloc = context.read<FieldEditorBloc>();
    return FlowyButton(
      text: FlowyText.medium(
        bloc.state.field!.fieldType.title(),
      ),
      leftIcon: FlowySvg(bloc.state.field!.fieldType.icon()),
      rightIcon: const FlowySvg(FlowySvgs.more_s),
    );
  }
}

typedef SelectFieldCallback = void Function(FieldType);

class FieldTypeList extends StatelessWidget with FlowyOverlayDelegate {
  final SelectFieldCallback onSelectField;
  const FieldTypeList({required this.onSelectField, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = FieldType.values.map((fieldType) {
      return FieldTypeCell(
        fieldType: fieldType,
        onSelectField: (fieldType) {
          onSelectField(fieldType);
          PopoverContainer.of(context).closeAll();
        },
      );
    }).toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        itemCount: cells.length,
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        physics: StyledScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class FieldTypeCell extends StatelessWidget {
  final FieldType fieldType;
  final SelectFieldCallback onSelectField;
  const FieldTypeCell({
    required this.fieldType,
    required this.onSelectField,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(fieldType.title()),
        onTap: () => onSelectField(fieldType),
        leftIcon: FlowySvg(fieldType.icon()),
      ),
    );
  }
}
