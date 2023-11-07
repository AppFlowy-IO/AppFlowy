import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_type_option_edit_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef SelectFieldCallback = void Function(FieldType);

class MobileFieldTypeList extends StatelessWidget {
  final FieldTypeOptionEditBloc bloc;
  final SelectFieldCallback onSelectField;
  const MobileFieldTypeList({
    required this.onSelectField,
    Key? key,
    required this.bloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = FieldType.values.map((fieldType) {
      return MobileFieldTypeCell(
        fieldType: fieldType,
        onSelectField: (fieldType) {
          onSelectField(fieldType);
        },
      );
    }).toList();

    return BlocProvider.value(
      value: bloc,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: cells.length,
        itemBuilder: (_, index) {
          return cells[index];
        },
      ),
    );
  }
}

class MobileFieldTypeCell extends StatelessWidget {
  final FieldType fieldType;
  final SelectFieldCallback onSelectField;
  const MobileFieldTypeCell({
    required this.fieldType,
    required this.onSelectField,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RadioListTile<FieldType>(
      dense: true,
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
      value: fieldType,
      groupValue: context.select(
        (FieldTypeOptionEditBloc bloc) => bloc.state.field.fieldType,
      ),
      onChanged: (value) {
        if (value != null) {
          onSelectField(value);
        }
      },
      title: Row(
        children: [
          FlowySvg(
            fieldType.icon(),
          ),
          const HSpace(8),
          Text(
            fieldType.title(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
        ],
      ),
    );
  }
}
