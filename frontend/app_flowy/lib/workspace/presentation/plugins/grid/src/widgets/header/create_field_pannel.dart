import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/create_field_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_name_input.dart';
import 'field_tyep_switcher.dart';

class CreateFieldPannel extends StatelessWidget {
  const CreateFieldPannel({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    const pannel = CreateFieldPannel();
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: pannel,
        constraints: BoxConstraints.loose(const Size(300, 200)),
      ),
      identifier: pannel.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
      style: FlowyOverlayStyle(blur: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CreateFieldBloc>()..add(const CreateFieldEvent.initial()),
      child: BlocBuilder<CreateFieldBloc, CreateFieldState>(
        builder: (context, state) {
          return state.field.fold(
            () => const SizedBox(),
            (field) => Column(children: [
              const FlowyText.medium("Edit property"),
              const VSpace(10),
              _FieldNameTextField(field),
              const VSpace(10),
              _FieldTypeSwitcher(field),
            ]),
          );
        },
      ),
    );
  }

  String identifier() {
    return toString();
  }
}

class _FieldTypeSwitcher extends StatelessWidget {
  final Field field;
  const _FieldTypeSwitcher(this.field, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FieldTypeSwitcher(
      field: field,
      onSelectField: _switchToFieldType,
    );
  }

  void _switchToFieldType(FieldType fieldType) {
    throw UnimplementedError();
  }
}

class _FieldNameTextField extends StatelessWidget {
  final Field field;
  const _FieldNameTextField(this.field, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FieldNameTextField(
      name: field.name,
      errorText: context.read<CreateFieldBloc>().state.errorText,
      onNameChanged: (newName) {
        context.read<CreateFieldBloc>().add(CreateFieldEvent.updateName(newName));
      },
    );
  }
}
