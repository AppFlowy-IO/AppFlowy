import 'dart:async';

import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';

import 'select_option_type_option_bloc.dart';
import 'type_option_service.dart';

class SingleSelectAction implements ISelectOptionAction {
  final TypeOptionBackendService service;
  final TypeOptionDataCallback onTypeOptionUpdated;

  SingleSelectAction({
    required this.onTypeOptionUpdated,
    required String viewId,
    required String fieldId,
  }) : service = TypeOptionBackendService(viewId: viewId, fieldId: fieldId);

  @override
  Future<List<SelectOptionPB>> insertOption(
    List<SelectOptionPB> options,
    String optionName,
  ) {
    final newOptions = List<SelectOptionPB>.from(options);
    return service.newOption(name: optionName).then((result) {
      return result.fold(
        (option) {
          final exists =
              newOptions.any((element) => element.name == option.name);
          if (!exists) {
            newOptions.insert(0, option);
          }

          _updateTypeOption(newOptions);
          return newOptions;
        },
        (err) {
          Log.error(err);
          return newOptions;
        },
      );
    });
  }

  @override
  List<SelectOptionPB> deleteOption(
    List<SelectOptionPB> options,
    SelectOptionPB deletedOption,
  ) {
    final newOptions = List<SelectOptionPB>.from(options);
    final index =
        newOptions.indexWhere((option) => option.id == deletedOption.id);
    if (index != -1) {
      newOptions.removeAt(index);
    }

    final newTypeOption = MultiSelectTypeOptionPB()..options.addAll(newOptions);
    onTypeOptionUpdated(newTypeOption.writeToBuffer());
    return newOptions;
  }

  @override
  List<SelectOptionPB> updateOption(
    List<SelectOptionPB> options,
    SelectOptionPB updatedOption,
  ) {
    final newOptions = List<SelectOptionPB>.from(options);
    final index =
        newOptions.indexWhere((option) => option.id == updatedOption.id);
    if (index != -1) {
      newOptions[index] = updatedOption;
    }

    _updateTypeOption(newOptions);
    return newOptions;
  }

  void _updateTypeOption(List<SelectOptionPB> options) {
    final newTypeOption = SingleSelectTypeOptionPB()..options.addAll(options);
    onTypeOptionUpdated(newTypeOption.writeToBuffer());
  }
}
