import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';

abstract class SelectOptionFilterDelegate {
  List<SelectOptionPB> loadOptions();
}

class SingleSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  final FilterInfo filterInfo;

  SingleSelectOptionFilterDelegateImpl({
    required this.filterInfo,
  });

  @override
  List<SelectOptionPB> loadOptions() {
    final parser = SingleSelectTypeOptionDataParser();
    return parser.fromBuffer(filterInfo.fieldInfo.field.typeOptionData).options;
  }
}

class MultiSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  final FilterInfo filterInfo;

  MultiSelectOptionFilterDelegateImpl({required this.filterInfo});

  @override
  List<SelectOptionPB> loadOptions() {
    final parser = MultiSelectTypeOptionDataParser();
    return parser.fromBuffer(filterInfo.fieldInfo.field.typeOptionData).options;
  }
}
