import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/create_field_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' hide Row;
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
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
        constraints: BoxConstraints.loose(const Size(220, 200)),
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
  void didRemove() async {
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
          return state.editContext.fold(
            () => const SizedBox(),
            (editContext) => ListView(
              shrinkWrap: true,
              children: [
                const FlowyText.medium("Edit property", fontSize: 12),
                const VSpace(10),
                _FieldNameTextField(editContext.gridField),
                const VSpace(10),
                _FieldTypeSwitcher(editContext),
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
  final EditFieldContext editContext;
  const _FieldTypeSwitcher(this.editContext, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FieldTypeSwitcher(editContext: editContext);
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
