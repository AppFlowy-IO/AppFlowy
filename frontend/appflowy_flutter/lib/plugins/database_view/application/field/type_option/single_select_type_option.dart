import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'select_option_type_option_bloc.dart';

class SingleSelectAction with ISelectOptionAction {
  final String viewId;
  final String fieldId;
  final SingleSelectTypeOptionPB typeOption;
  final TypeOptionDataCallback onTypeOptionUpdated;

  const SingleSelectAction({
    required this.viewId,
    required this.fieldId,
    required this.typeOption,
    required this.onTypeOptionUpdated,
  });

  @override
  List<SelectOptionPB> Function(SelectOptionPB) get deleteOption {
    return (SelectOptionPB option) {
      typeOption.freeze();
      final newTypeOption = typeOption.rebuild((typeOption) {
        final index =
            typeOption.options.indexWhere((element) => element.id == option.id);
        if (index != -1) {
          typeOption.options.removeAt(index);
        }
      });
      onTypeOptionUpdated.call(newTypeOption.writeToBuffer());
      return newTypeOption.options;
    };
  }

  @override
  Future<List<SelectOptionPB>> Function(String) get insertOption {
    return (String optionName) {
      return newOption(viewId: viewId, fieldId: fieldId, name: optionName)
          .then((result) {
        return result.fold(
          (option) {
            typeOption.freeze();
            final newTypeOption = typeOption.rebuild((typeOption) {
              final exists = typeOption.options
                  .any((element) => element.name == option.name);
              if (!exists) {
                typeOption.options.insert(0, option);
              }
            });
            onTypeOptionUpdated.call(newTypeOption.writeToBuffer());
            return newTypeOption.options;
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
      final newTypeOption = typeOption.rebuild((typeOption) {
        final index =
            typeOption.options.indexWhere((element) => element.id == option.id);
        if (index != -1) {
          typeOption.options[index] = option;
        }
      });
      onTypeOptionUpdated.call(newTypeOption.writeToBuffer());
      return newTypeOption.options;
    };
  }
}
