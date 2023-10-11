import 'package:appflowy/plugins/database_view/application/field/type_option/multi_select_type_option.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';

import 'builder.dart';
import 'select_option.dart';

class MultiSelectTypeOptionEditor extends StatelessWidget {
  final String viewId;
  final FieldPB field;
  late final MultiSelectTypeOptionPB typeOption;
  late final MultiSelectAction selectOptionAction;
  final PopoverMutex? popoverMutex;

  MultiSelectTypeOptionEditor({
    required this.viewId,
    required this.field,
    required TypeOptionDataCallback onTypeOptionUpdated,
    required MultiSelectTypeOptionParser parser,
    this.popoverMutex,
    super.key,
  }) {
    typeOption = parser.fromBuffer(field.typeOptionData);
    selectOptionAction = MultiSelectAction(
      fieldId: field.id,
      viewId: viewId,
      typeOption: typeOption,
      onTypeOptionUpdated: onTypeOptionUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectOptionTypeOptionEditor(
      options: selectOptionAction.typeOption.options,
      beginEdit: () => PopoverContainer.of(context).closeAll(),
      popoverMutex: popoverMutex,
      typeOptionAction: selectOptionAction,
    );
  }
}
