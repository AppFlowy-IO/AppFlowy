import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';

abstract class SelectOptionFilterDelegate {
  Future<List<SelectOptionPB>> loadOptions();
}

class SingleSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  final SingleSelectTypeOptionContext typeOptionContext;

  SingleSelectOptionFilterDelegateImpl(FilterInfo filterInfo)
      : typeOptionContext = makeSingleSelectTypeOptionContext(
          gridId: filterInfo.viewId,
          fieldPB: filterInfo.fieldInfo.field,
        );

  @override
  Future<List<SelectOptionPB>> loadOptions() {
    return typeOptionContext
        .loadTypeOptionData(
          onError: (error) => Log.error(error),
        )
        .then((value) => value.options);
  }
}

class MultiSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  final MultiSelectTypeOptionContext typeOptionContext;

  MultiSelectOptionFilterDelegateImpl(FilterInfo filterInfo)
      : typeOptionContext = makeMultiSelectTypeOptionContext(
          gridId: filterInfo.viewId,
          fieldPB: filterInfo.fieldInfo.field,
        );

  @override
  Future<List<SelectOptionPB>> loadOptions() {
    return typeOptionContext
        .loadTypeOptionData(
          onError: (error) => Log.error(error),
        )
        .then((value) => value.options);
  }
}
