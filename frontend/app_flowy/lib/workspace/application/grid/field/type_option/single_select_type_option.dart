import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/single_select_type_option.pb.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'select_option_type_option_bloc.dart';
import 'type_option_service.dart';

class SingleSelectTypeOptionContext extends TypeOptionWidgetContext<SingleSelectTypeOption>
    with SelectOptionTypeOptionAction {
  final TypeOptionService service;

  SingleSelectTypeOptionContext({
    required SingleSelectTypeOptionWidgetDataParser dataBuilder,
    required GridFieldContext fieldContext,
  })  : service = TypeOptionService(
          gridId: fieldContext.gridId,
          fieldId: fieldContext.field.id,
        ),
        super(dataBuilder: dataBuilder, fieldContext: fieldContext);

  @override
  List<SelectOption> Function(SelectOption) get deleteOption {
    return (SelectOption option) {
      typeOption.freeze();
      typeOption = typeOption.rebuild((typeOption) {
        final index = typeOption.options.indexWhere((element) => element.id == option.id);
        if (index != -1) {
          typeOption.options.removeAt(index);
        }
      });
      return typeOption.options;
    };
  }

  @override
  Future<List<SelectOption>> Function(String) get insertOption {
    return (String optionName) {
      return service.newOption(name: optionName).then((result) {
        return result.fold(
          (option) {
            typeOption.freeze();
            typeOption = typeOption.rebuild((typeOption) {
              typeOption.options.insert(0, option);
            });

            return typeOption.options;
          },
          (err) {
            Log.error(err);
            return typeOption.options;
          },
        );
      });
    };
  }

  @override
  List<SelectOption> Function(SelectOption) get udpateOption {
    return (SelectOption option) {
      typeOption.freeze();
      typeOption = typeOption.rebuild((typeOption) {
        final index = typeOption.options.indexWhere((element) => element.id == option.id);
        if (index != -1) {
          typeOption.options[index] = option;
        }
      });
      return typeOption.options;
    };
  }
}

class SingleSelectTypeOptionWidgetDataParser extends TypeOptionWidgetDataParser<SingleSelectTypeOption> {
  @override
  SingleSelectTypeOption fromBuffer(List<int> buffer) {
    return SingleSelectTypeOption.fromBuffer(buffer);
  }
}
