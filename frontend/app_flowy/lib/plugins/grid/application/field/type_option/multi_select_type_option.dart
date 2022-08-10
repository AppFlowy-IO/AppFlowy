import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/multi_select_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'dart:async';
import 'select_option_type_option_bloc.dart';
import 'type_option_context.dart';
import 'type_option_data_controller.dart';
import 'type_option_service.dart';
import 'package:protobuf/protobuf.dart';

class MultiSelectTypeOptionContext
    extends TypeOptionContext<MultiSelectTypeOption> with ISelectOptionAction {
  final TypeOptionFFIService service;

  MultiSelectTypeOptionContext({
    required MultiSelectTypeOptionWidgetDataParser dataParser,
    required TypeOptionDataController dataController,
  })  : service = TypeOptionFFIService(
          gridId: dataController.gridId,
          fieldId: dataController.field.id,
        ),
        super(dataParser: dataParser, dataController: dataController);

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
  List<SelectOptionPB> Function(SelectOptionPB) get updateOption {
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
