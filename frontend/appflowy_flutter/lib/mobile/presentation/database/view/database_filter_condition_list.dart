import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checklist.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/number.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/condition_list.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

abstract class FilterCondition<C> {
  static FilterCondition fromFieldType(FieldType fieldType) {
    return switch (fieldType) {
      FieldType.RichText || FieldType.URL => TextFilterCondition().as(),
      FieldType.Number => NumberFilterCondition().as(),
      FieldType.Checkbox => CheckboxFilterCondition().as(),
      FieldType.Checklist => ChecklistFilterCondition().as(),
      FieldType.SingleSelect => SingleSelectOptionFilterCondition().as(),
      FieldType.MultiSelect => MultiSelectOptionFilterCondition().as(),
      _ => MultiSelectOptionFilterCondition().as(),
    };
  }

  List<(C, String)> get conditions;
}

mixin _GenericCastHelper {
  FilterCondition<T> as<T>() => this as FilterCondition<T>;
}

final class TextFilterCondition
    with _GenericCastHelper
    implements FilterCondition<TextFilterConditionPB> {
  @override
  List<(TextFilterConditionPB, String)> get conditions {
    return [
      TextFilterConditionPB.TextContains,
      TextFilterConditionPB.TextDoesNotContain,
      TextFilterConditionPB.TextIs,
      TextFilterConditionPB.TextIsNot,
      TextFilterConditionPB.TextStartsWith,
      TextFilterConditionPB.TextEndsWith,
      TextFilterConditionPB.TextIsEmpty,
      TextFilterConditionPB.TextIsNotEmpty,
    ].map((e) => (e, e.filterName)).toList();
  }
}

final class NumberFilterCondition
    with _GenericCastHelper
    implements FilterCondition<NumberFilterConditionPB> {
  @override
  List<(NumberFilterConditionPB, String)> get conditions {
    return [
      NumberFilterConditionPB.Equal,
      NumberFilterConditionPB.NotEqual,
      NumberFilterConditionPB.LessThan,
      NumberFilterConditionPB.LessThanOrEqualTo,
      NumberFilterConditionPB.GreaterThan,
      NumberFilterConditionPB.GreaterThanOrEqualTo,
      NumberFilterConditionPB.NumberIsEmpty,
      NumberFilterConditionPB.NumberIsNotEmpty,
    ].map((e) => (e, e.filterName)).toList();
  }
}

final class CheckboxFilterCondition
    with _GenericCastHelper
    implements FilterCondition<CheckboxFilterConditionPB> {
  @override
  List<(CheckboxFilterConditionPB, String)> get conditions {
    return [
      CheckboxFilterConditionPB.IsChecked,
      CheckboxFilterConditionPB.IsUnChecked,
    ].map((e) => (e, e.filterName)).toList();
  }
}

final class ChecklistFilterCondition
    with _GenericCastHelper
    implements FilterCondition<ChecklistFilterConditionPB> {
  @override
  List<(ChecklistFilterConditionPB, String)> get conditions {
    return [
      ChecklistFilterConditionPB.IsComplete,
      ChecklistFilterConditionPB.IsIncomplete,
    ].map((e) => (e, e.filterName)).toList();
  }
}

final class SingleSelectOptionFilterCondition
    with _GenericCastHelper
    implements FilterCondition<SelectOptionFilterConditionPB> {
  @override
  List<(SelectOptionFilterConditionPB, String)> get conditions {
    return [
      SelectOptionFilterConditionPB.OptionIs,
      SelectOptionFilterConditionPB.OptionIsNot,
      SelectOptionFilterConditionPB.OptionIsEmpty,
      SelectOptionFilterConditionPB.OptionIsNotEmpty,
    ].map((e) => (e, e.i18n)).toList();
  }
}

final class MultiSelectOptionFilterCondition
    with _GenericCastHelper
    implements FilterCondition<SelectOptionFilterConditionPB> {
  @override
  List<(SelectOptionFilterConditionPB, String)> get conditions {
    return [
      SelectOptionFilterConditionPB.OptionContains,
      SelectOptionFilterConditionPB.OptionDoesNotContain,
      SelectOptionFilterConditionPB.OptionIsEmpty,
      SelectOptionFilterConditionPB.OptionIsNotEmpty,
    ].map((e) => (e, e.i18n)).toList();
  }
}
