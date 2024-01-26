import 'dart:async';

import 'package:appflowy/plugins/database/domain/type_option_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';

abstract class ISelectOptionAction {
  ISelectOptionAction({
    required this.onTypeOptionUpdated,
    required String viewId,
    required String fieldId,
  }) : service = TypeOptionBackendService(viewId: viewId, fieldId: fieldId);

  final TypeOptionBackendService service;
  final TypeOptionDataCallback onTypeOptionUpdated;

  void updateTypeOption(List<SelectOptionPB> options) {
    final newTypeOption = MultiSelectTypeOptionPB()..options.addAll(options);
    onTypeOptionUpdated(newTypeOption.writeToBuffer());
  }

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

          updateTypeOption(newOptions);
          return newOptions;
        },
        (err) {
          Log.error(err);
          return newOptions;
        },
      );
    });
  }

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

    updateTypeOption(newOptions);
    return newOptions;
  }

  List<SelectOptionPB> updateOption(
    List<SelectOptionPB> options,
    SelectOptionPB option,
  ) {
    final newOptions = List<SelectOptionPB>.from(options);
    final index = newOptions.indexWhere((element) => element.id == option.id);
    if (index != -1) {
      newOptions[index] = option;
    }

    updateTypeOption(newOptions);
    return newOptions;
  }
}

class MultiSelectAction extends ISelectOptionAction {
  MultiSelectAction({
    required super.viewId,
    required super.fieldId,
    required super.onTypeOptionUpdated,
  });

  @override
  void updateTypeOption(List<SelectOptionPB> options) {
    final newTypeOption = MultiSelectTypeOptionPB()..options.addAll(options);
    onTypeOptionUpdated(newTypeOption.writeToBuffer());
  }
}

class SingleSelectAction extends ISelectOptionAction {
  SingleSelectAction({
    required super.viewId,
    required super.fieldId,
    required super.onTypeOptionUpdated,
  });

  @override
  void updateTypeOption(List<SelectOptionPB> options) {
    final newTypeOption = SingleSelectTypeOptionPB()..options.addAll(options);
    onTypeOptionUpdated(newTypeOption.writeToBuffer());
  }
}
