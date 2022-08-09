import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/multi_select_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'select_option_type_option_bloc.dart';
import 'type_option_service.dart';

class MultiSelectTypeOptionContext
    extends TypeOptionWidgetContext<MultiSelectTypeOption>
    with SelectOptionTypeOptionAction {
  final TypeOptionService service;

  MultiSelectTypeOptionContext({
    required MultiSelectTypeOptionWidgetDataParser dataBuilder,
    required TypeOptionDataController dataController,
  })  : service = TypeOptionService(
          gridId: dataController.gridId,
          fieldId: dataController.field.id,
        ),
        super(dataParser: dataBuilder, dataController: dataController);

  @override
  List<SelectOptionPB> Function(SelectOptionPB) get deleteOption {
    return (SelectOptionPB option) {
      typeOption.freeze();
      typeOption = typeOption.rebuild((typeOption) {
        final index =
            typeOption.options.indexWhere((element) => element.id == option.id);
        if (index != -1) {
          typeOption.options.removeAt(index);
        }
      });
      return typeOption.options;
    };
  }

  @override
  Future<List<SelectOptionPB>> Function(String) get insertOption {
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
  List<SelectOptionPB> Function(SelectOptionPB) get udpateOption {
    return (SelectOptionPB option) {
      typeOption.freeze();
      typeOption = typeOption.rebuild((typeOption) {
        final index =
            typeOption.options.indexWhere((element) => element.id == option.id);
        if (index != -1) {
          typeOption.options[index] = option;
        }
      });
      return typeOption.options;
    };
  }
}

class MultiSelectTypeOptionWidgetDataParser
    extends TypeOptionDataParser<MultiSelectTypeOption> {
  @override
  MultiSelectTypeOption fromBuffer(List<int> buffer) {
    return MultiSelectTypeOption.fromBuffer(buffer);
  }
}
