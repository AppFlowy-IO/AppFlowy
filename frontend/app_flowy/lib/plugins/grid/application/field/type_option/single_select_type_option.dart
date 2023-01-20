import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/single_select_type_option.pb.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'select_option_type_option_bloc.dart';
import 'type_option_context.dart';
import 'type_option_service.dart';

class SingleSelectAction with ISelectOptionAction {
  final String gridId;
  final String fieldId;
  final SingleSelectTypeOptionContext typeOptionContext;
  final TypeOptionFFIService service;

  SingleSelectAction({
    required this.gridId,
    required this.fieldId,
    required this.typeOptionContext,
  }) : service = TypeOptionFFIService(gridId: gridId, fieldId: fieldId);

  SingleSelectTypeOptionPB get typeOption => typeOptionContext.typeOption;

  set typeOption(SingleSelectTypeOptionPB newTypeOption) {
    typeOptionContext.typeOption = newTypeOption;
  }

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
              final exists = typeOption.options
                  .any((element) => element.name == option.name);
              if (!exists) {
                typeOption.options.insert(0, option);
              }
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
