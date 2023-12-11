import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_type_option_edit_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef SelectFieldCallback = void Function(FieldType);

class MobileFieldTypeList extends StatelessWidget {
  const MobileFieldTypeList({
    super.key,
    required this.onSelectField,
    required this.bloc,
  });

  final FieldTypeOptionEditBloc bloc;
  final SelectFieldCallback onSelectField;

  @override
  Widget build(BuildContext context) {
    const allFieldTypes = FieldType.values;
    return BlocProvider.value(
      value: bloc,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: allFieldTypes.length,
        itemBuilder: (_, index) {
          return MobileFieldTypeCell(
            fieldType: allFieldTypes[index],
            onSelectField: onSelectField,
          );
        },
      ),
    );
  }
}

class MobileFieldTypeCell extends StatelessWidget {
  const MobileFieldTypeCell({
    super.key,
    required this.fieldType,
    required this.onSelectField,
  });

  final FieldType fieldType;
  final SelectFieldCallback onSelectField;

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
