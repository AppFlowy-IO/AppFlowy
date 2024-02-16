import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';

abstract class SelectOptionFilterDelegate {
  List<SelectOptionPB> loadOptions();
}

class SingleSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  SingleSelectOptionFilterDelegateImpl({required this.filterInfo});

  final FilterInfo filterInfo;

  @override
  List<SelectOptionPB> loadOptions() {
    final parser = SingleSelectTypeOptionDataParser();
    return parser.fromBuffer(filterInfo.fieldInfo.field.typeOptionData).options;
  }
}

class MultiSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  MultiSelectOptionFilterDelegateImpl({required this.filterInfo});

  final FilterInfo filterInfo;

  @override
  List<SelectOptionPB> loadOptions() {
    final parser = MultiSelectTypeOptionDataParser();
    return parser.fromBuffer(filterInfo.fieldInfo.field.typeOptionData).options;
  }
}
