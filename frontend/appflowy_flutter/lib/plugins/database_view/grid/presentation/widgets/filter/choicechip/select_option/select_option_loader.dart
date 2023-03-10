import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';

import '../../filter_info.dart';

abstract class SelectOptionFilterDelegate {
  Future<List<SelectOptionPB>> loadOptions();
}

class SingleSelectOptionFilterDelegateImpl
    implements SelectOptionFilterDelegate {
  final SingleSelectTypeOptionContext typeOptionContext;

  SingleSelectOptionFilterDelegateImpl(FilterInfo filterInfo)
      : typeOptionContext = makeSingleSelectTypeOptionContext(
          viewId: filterInfo.viewId,
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
          viewId: filterInfo.viewId,
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
