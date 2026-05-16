import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

abstract class SelectOptionFilterDelegate {
  const SelectOptionFilterDelegate();

  List<SelectOptionPB> getOptions(FieldInfo fieldInfo);
}

class SingleSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  const SingleSelectOptionFilterDelegateImpl();

  @override
  List<SelectOptionPB> getOptions(FieldInfo fieldInfo) {
    final parser = SingleSelectTypeOptionDataParser();
    return parser.fromBuffer(fieldInfo.field.typeOptionData).options;
  }
}

class MultiSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  const MultiSelectOptionFilterDelegateImpl();

  @override
  List<SelectOptionPB> getOptions(FieldInfo fieldInfo) {
    return MultiSelectTypeOptionDataParser()
        .fromBuffer(fieldInfo.field.typeOptionData)
        .options;
  }
}
