import 'package:appflowy/plugins/database/application/field/type_option/select_type_option_actions.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import 'builder.dart';
import 'select/select_option.dart';

class MultiSelectTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const MultiSelectTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = _parseTypeOptionData(field.typeOptionData);

    return SelectOptionTypeOptionWidget(
      options: typeOption.options,
      beginEdit: () => PopoverContainer.of(context).closeAll(),
      popoverMutex: popoverMutex,
      typeOptionAction: MultiSelectAction(
        viewId: viewId,
        fieldId: field.id,
        onTypeOptionUpdated: onTypeOptionUpdated,
      ),
    );
  }

  MultiSelectTypeOptionPB _parseTypeOptionData(List<int> data) {
    return MultiSelectTypeOptionDataParser().fromBuffer(data);
  }
}
