import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/create_field_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/switch_field_type_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' hide Row;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'field_name_input.dart';
import 'field_tyep_switcher.dart';

class CreateFieldPannel extends FlowyOverlayDelegate {
  final String gridId;
  final CreateFieldBloc _createFieldBloc;
  CreateFieldPannel({required this.gridId, Key? key}) : _createFieldBloc = getIt<CreateFieldBloc>(param1: gridId) {
    _createFieldBloc.add(const CreateFieldEvent.initial());
  }

  void show(BuildContext context, String gridId) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: _CreateFieldPannelWidget(_createFieldBloc),
        constraints: BoxConstraints.loose(const Size(220, 400)),
      ),
      identifier: identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  String identifier() {
    return toString();
  }

  @override
  void didRemove() {
    _createFieldBloc.add(const CreateFieldEvent.done());
  }
}

class _CreateFieldPannelWidget extends StatelessWidget {
  final CreateFieldBloc createFieldBloc;
  const _CreateFieldPannelWidget(this.createFieldBloc, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: createFieldBloc,
      child: BlocBuilder<CreateFieldBloc, CreateFieldState>(
        builder: (context, state) {
          return state.field.fold(
            () => const SizedBox(width: 200),
            (field) => ListView(
              shrinkWrap: true,
              children: [
                const FlowyText.medium("Edit property", fontSize: 12),
                const VSpace(10),
                const _FieldNameTextField(),
                const VSpace(10),
                _FieldTypeSwitcher(SwitchFieldContext(state.gridId, field, state.typeOptionData)),
                const VSpace(10),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldTypeSwitcher extends StatelessWidget {
  final SwitchFieldContext switchContext;
  const _FieldTypeSwitcher(this.switchContext, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FieldTypeSwitcher(
      switchContext: switchContext,
      onSelected: (field, typeOptionData) {
        context.read<CreateFieldBloc>().add(CreateFieldEvent.switchField(field, typeOptionData));
      },
    );
  }
}

class _FieldNameTextField extends StatelessWidget {
  const _FieldNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateFieldBloc, CreateFieldState>(
      buildWhen: (previous, current) => previous.fieldName != current.fieldName,
      builder: (context, state) {
        return FieldNameTextField(
          name: state.fieldName,
          errorText: context.read<CreateFieldBloc>().state.errorText,
          onNameChanged: (newName) {
            context.read<CreateFieldBloc>().add(CreateFieldEvent.updateName(newName));
          },
        );
      },
    );
  }
}
