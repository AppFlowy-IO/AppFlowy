import 'dart:typed_data';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_type_option_edit_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_data_controller.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    super.key,
    required TypeOptionController dataController,
    required this.popoverMutex,
  }) : _dataController = dataController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return FieldTypeOptionEditBloc(_dataController)
          ..add(const FieldTypeOptionEditEvent.initial());
      },
      child: BlocBuilder<FieldTypeOptionEditBloc, FieldTypeOptionEditState>(
        builder: (context, state) {
          final typeOptionWidget = _typeOptionWidget(
            context: context,
            state: state,
          );

          final List<Widget> children = [
            SwitchFieldButton(popoverMutex: popoverMutex),
            if (typeOptionWidget != null) typeOptionWidget,
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
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

class SwitchFieldButton extends StatefulWidget {
  final PopoverMutex popoverMutex;
  const SwitchFieldButton({
    super.key,
    required this.popoverMutex,
  });

  @override
  State<SwitchFieldButton> createState() => _SwitchFieldButtonState();
}

class _SwitchFieldButtonState extends State<SwitchFieldButton> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final child = AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(460, 540)),
      triggerActions: PopoverTriggerFlags.hover,
      mutex: widget.popoverMutex,
      controller: _popoverController,
      offset: const Offset(8, 0),
      margin: const EdgeInsets.all(8),
      popupBuilder: (BuildContext popoverContext) {
        return FieldTypeList(
          onSelectField: (newFieldType) {
            context
                .read<FieldTypeOptionEditBloc>()
                .add(FieldTypeOptionEditEvent.switchToField(newFieldType));
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: _buildMoreButton(context),
      ),
    );

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: child,
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final bloc = context.read<FieldTypeOptionEditBloc>();
    return FlowyButton(
      onTap: () => _popoverController.show(),
      text: FlowyText.medium(
        bloc.state.field.fieldType.title(),
      ),
      leftIcon: FlowySvg(bloc.state.field.fieldType.icon()),
      rightIcon: const FlowySvg(FlowySvgs.more_s),
    );
  }
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({super.key});
}
