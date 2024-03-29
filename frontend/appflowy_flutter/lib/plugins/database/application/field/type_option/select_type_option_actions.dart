import 'package:appflowy/plugins/database/domain/type_option_service.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:nanoid/nanoid.dart';

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

  List<SelectOptionPB> insertOption(
    List<SelectOptionPB> options,
    String optionName,
  ) {
    if (options.any((element) => element.name == optionName)) {
      return options;
    }

    final newOptions = List<SelectOptionPB>.from(options);

    final newSelectOption = SelectOptionPB()
      ..id = nanoid(4)
      ..color = newSelectOptionColor(options)
      ..name = optionName;

    newOptions.insert(0, newSelectOption);

    updateTypeOption(newOptions);
    return newOptions;
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

  List<SelectOptionPB> reorderOption(
    List<SelectOptionPB> options,
    String fromOptionId,
    String toOptionId,
  ) {
    final newOptions = List<SelectOptionPB>.from(options);
    final fromIndex =
        newOptions.indexWhere((element) => element.id == fromOptionId);
    final toIndex =
        newOptions.indexWhere((element) => element.id == toOptionId);

    if (fromIndex != -1 && toIndex != -1) {
      newOptions.insert(toIndex, newOptions.removeAt(fromIndex));
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

SelectOptionColorPB newSelectOptionColor(List<SelectOptionPB> options) {
  final colorFrequency = List.filled(SelectOptionColorPB.values.length, 0);

  for (final option in options) {
    colorFrequency[option.color.value]++;
  }

  final minIndex = colorFrequency
      .asMap()
      .entries
      .reduce((a, b) => a.value <= b.value ? a : b)
      .key;

  return SelectOptionColorPB.valueOf(minIndex) ?? SelectOptionColorPB.Purple;
}
