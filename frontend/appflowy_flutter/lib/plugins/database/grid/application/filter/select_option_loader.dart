import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

abstract class SelectOptionFilterDelegate {
  const SelectOptionFilterDelegate();

  List<SelectOptionPB> getOptions(FieldInfo fieldInfo);

  Set<String> selectOption(
    List<String> currentOptionIds,
    String optionId,
    SelectOptionFilterConditionPB condition,
  );
}

class SingleSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  const SingleSelectOptionFilterDelegateImpl();

  @override
  List<SelectOptionPB> getOptions(FieldInfo fieldInfo) {
    final parser = SingleSelectTypeOptionDataParser();
    return parser.fromBuffer(fieldInfo.field.typeOptionData).options;
  }

  @override
  Set<String> selectOption(
    List<String> currentOptionIds,
    String optionId,
    SelectOptionFilterConditionPB condition,
  ) {
    final selectOptionIds = Set<String>.from(currentOptionIds);

    switch (condition) {
      case SelectOptionFilterConditionPB.OptionIs:
        if (selectOptionIds.isNotEmpty) {
          selectOptionIds.clear();
        }
        selectOptionIds.add(optionId);
        break;
      case SelectOptionFilterConditionPB.OptionIsNot:
      case SelectOptionFilterConditionPB.OptionContains:
      case SelectOptionFilterConditionPB.OptionDoesNotContain:
        selectOptionIds.add(optionId);
        break;
      case SelectOptionFilterConditionPB.OptionIsEmpty ||
            SelectOptionFilterConditionPB.OptionIsNotEmpty:
        selectOptionIds.clear();
        break;
      default:
        throw UnimplementedError();
    }

    return selectOptionIds;
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

  @override
  Set<String> selectOption(
    List<String> currentOptionIds,
    String optionId,
    SelectOptionFilterConditionPB condition,
  ) =>
      Set<String>.from(currentOptionIds)..add(optionId);
}
