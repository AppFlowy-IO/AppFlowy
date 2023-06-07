import 'dart:typed_data';
import 'package:appflowy/plugins/database_view/application/field/field_type_option_edit_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_data_controller.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../layout/sizes.dart';
import 'field_type_extension.dart';
import 'field_type_list.dart';
import 'type_option/builder.dart';

typedef UpdateFieldCallback = void Function(FieldPB, Uint8List);
typedef SwitchToFieldCallback = Future<Either<TypeOptionPB, FlowyError>>
    Function(
  String fieldId,
  FieldType fieldType,
);

class FieldTypeOptionEditor extends StatelessWidget {
  final TypeOptionController _dataController;
  final PopoverMutex popoverMutex;

  const FieldTypeOptionEditor({
    required TypeOptionController dataController,
    required this.popoverMutex,
    Key? key,
  })  : _dataController = dataController,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = FieldTypeOptionEditBloc(_dataController);
        bloc.add(const FieldTypeOptionEditEvent.initial());
        return bloc;
      },
      child: BlocBuilder<FieldTypeOptionEditBloc, FieldTypeOptionEditState>(
        builder: (context, state) {
          final typeOptionWidget = _typeOptionWidget(
            context: context,
            state: state,
          );

          final List<Widget> children = [
            _SwitchFieldButton(popoverMutex: popoverMutex),
            if (typeOptionWidget != null) typeOptionWidget
          ];

          return ListView(
            shrinkWrap: true,
            children: children,
          );
        },
      ),
    );
  }

  Widget? _typeOptionWidget({
    required BuildContext context,
    required FieldTypeOptionEditState state,
  }) {
    return makeTypeOptionWidget(
      context: context,
      dataController: _dataController,
      popoverMutex: popoverMutex,
    );
  }
}

class _SwitchFieldButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const _SwitchFieldButton({
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
                .read<FieldTypeOptionEditBloc>()
                .add(FieldTypeOptionEditEvent.switchToField(newFieldType));
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
    final bloc = context.read<FieldTypeOptionEditBloc>();
    return FlowyButton(
      text: FlowyText.medium(
        bloc.state.field.fieldType.title(),
      ),
      margin: GridSize.typeOptionContentInsets,
      leftIcon: FlowySvg(name: bloc.state.field.fieldType.iconName()),
      rightIcon: const FlowySvg(name: 'grid/more'),
    );
  }
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}
