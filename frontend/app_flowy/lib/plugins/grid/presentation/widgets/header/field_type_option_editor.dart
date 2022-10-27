import 'dart:typed_data';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_data_controller.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import '../../layout/sizes.dart';
import 'field_type_extension.dart';
import 'field_type_list.dart';
import 'type_option/builder.dart';

typedef UpdateFieldCallback = void Function(FieldPB, Uint8List);
typedef SwitchToFieldCallback
    = Future<Either<FieldTypeOptionDataPB, FlowyError>> Function(
  String fieldId,
  FieldType fieldType,
);

class FieldTypeOptionEditor extends StatelessWidget {
  final TypeOptionDataController _dataController;
  final PopoverMutex popoverMutex;

  const FieldTypeOptionEditor({
    required TypeOptionDataController dataController,
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

          List<Widget> children = [
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
      triggerActions: PopoverTriggerFlags.click | PopoverTriggerFlags.hover,
      mutex: popoverMutex,
      offset: const Offset(20, 0),
      popupBuilder: (popOverContext) {
        return FieldTypeList(onSelectField: (newFieldType) {
          context
              .read<FieldTypeOptionEditBloc>()
              .add(FieldTypeOptionEditEvent.switchToField(newFieldType));
        });
      },
      child: _buildMoreButton(context),
    );

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: widget,
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    final bloc = context.read<FieldTypeOptionEditBloc>();
    return FlowyButton(
      text: FlowyText.medium(
        bloc.state.field.fieldType.title(),
        fontSize: 12,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      hoverColor: theme.hover,
      leftIcon: svgWidget(
        bloc.state.field.fieldType.iconName(),
        color: theme.iconColor,
      ),
      rightIcon: svgWidget("grid/more", color: theme.iconColor),
    );
  }
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}
