import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/select_option/select_option_loader.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_filter_list_bloc.freezed.dart';

class SelectOptionFilterListBloc<T>
    extends Bloc<SelectOptionFilterListEvent, SelectOptionFilterListState> {
  final SelectOptionFilterDelegate delegate;
  SelectOptionFilterListBloc({
    required String viewId,
    required FieldPB fieldPB,
    required this.delegate,
    required List<String> selectedOptionIds,
  }) : super(SelectOptionFilterListState.initial(selectedOptionIds)) {
    on<SelectOptionFilterListEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          selectOption: (option) {
            final selectedOptionIds = Set<String>.from(state.selectedOptionIds);
            selectedOptionIds.add(option.id);

            _updateSelectOptions(
              selectedOptionIds: selectedOptionIds,
              emit: emit,
            );
          },
          unselectOption: (option) {
            final selectedOptionIds = Set<String>.from(state.selectedOptionIds);
            selectedOptionIds.remove(option.id);

            _updateSelectOptions(
              selectedOptionIds: selectedOptionIds,
              emit: emit,
            );
          },
          didReceiveOptions: (newOptions) {
            List<SelectOptionPB> options = List.from(newOptions);
            options.retainWhere(
                (element) => element.name.contains(state.predicate));

            final visibleOptions = options.map((option) {
              return VisibleSelectOption(
                  option, state.selectedOptionIds.contains(option.id));
            }).toList();

            emit(state.copyWith(
                options: options, visibleOptions: visibleOptions));
          },
          filterOption: (optionName) {
            _updateSelectOptions(predicate: optionName, emit: emit);
          },
        );
      },
    );
  }

  void _updateSelectOptions({
    String? predicate,
    Set<String>? selectedOptionIds,
    required Emitter<SelectOptionFilterListState> emit,
  }) {
    final List<VisibleSelectOption> visibleOptions = _makeVisibleOptions(
      predicate ?? state.predicate,
      selectedOptionIds ?? state.selectedOptionIds,
    );

    emit(state.copyWith(
      predicate: predicate ?? state.predicate,
      visibleOptions: visibleOptions,
      selectedOptionIds: selectedOptionIds ?? state.selectedOptionIds,
    ));
  }

  List<VisibleSelectOption> _makeVisibleOptions(
    String predicate,
    Set<String> selectedOptionIds,
  ) {
    List<SelectOptionPB> options = List.from(state.options);
    options.retainWhere((element) => element.name.contains(predicate));

    return options.map((option) {
      return VisibleSelectOption(option, selectedOptionIds.contains(option.id));
    }).toList();
  }

  void _loadOptions() {
    delegate.loadOptions().then((options) {
      if (!isClosed) {
        add(SelectOptionFilterListEvent.didReceiveOptions(options));
      }
    });
  }

  void _startListening() {}
}

@freezed
class SelectOptionFilterListEvent with _$SelectOptionFilterListEvent {
  const factory SelectOptionFilterListEvent.initial() = _Initial;
  const factory SelectOptionFilterListEvent.selectOption(
      SelectOptionPB option) = _SelectOption;
  const factory SelectOptionFilterListEvent.unselectOption(
      SelectOptionPB option) = _UnSelectOption;
  const factory SelectOptionFilterListEvent.didReceiveOptions(
      List<SelectOptionPB> options) = _DidReceiveOptions;
  const factory SelectOptionFilterListEvent.filterOption(String optionName) =
      _SelectOptionFilter;
}

@freezed
class SelectOptionFilterListState with _$SelectOptionFilterListState {
  const factory SelectOptionFilterListState({
    required List<SelectOptionPB> options,
    required List<VisibleSelectOption> visibleOptions,
    required Set<String> selectedOptionIds,
    required String predicate,
  }) = _SelectOptionFilterListState;

  factory SelectOptionFilterListState.initial(List<String> selectedOptionIds) {
    return SelectOptionFilterListState(
      options: [],
      predicate: '',
      visibleOptions: [],
      selectedOptionIds: selectedOptionIds.toSet(),
    );
  }
}

class VisibleSelectOption {
  final SelectOptionPB optionPB;
  final bool isSelected;

  VisibleSelectOption(this.optionPB, this.isSelected);
}
