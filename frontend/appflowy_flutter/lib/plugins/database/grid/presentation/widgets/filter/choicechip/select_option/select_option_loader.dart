import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

abstract class SelectOptionFilterDelegate {
  List<SelectOptionPB> loadOptions();

  Set<String> selectOption(
    Set<String> currentOptionIds,
    String optionId,
    SelectOptionFilterConditionPB condition,
  );
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

  @override
  Set<String> selectOption(
    Set<String> currentOptionIds,
    String optionId,
    SelectOptionFilterConditionPB condition,
  ) {
    final selectOptionIds = Set<String>.from(currentOptionIds);

    if (condition == SelectOptionFilterConditionPB.OptionIsNot ||
        selectOptionIds.isEmpty) {
      selectOptionIds.add(optionId);
    }

    return selectOptionIds;
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

  @override
  Set<String> selectOption(
    Set<String> currentOptionIds,
    String optionId,
    SelectOptionFilterConditionPB condition,
  ) =>
      Set<String>.from(currentOptionIds)..add(optionId);
}
