import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'simple_text_filter_bloc.freezed.dart';

class SimpleTextFilterBloc<T>
    extends Bloc<SimpleTextFilterEvent<T>, SimpleTextFilterState<T>> {
  SimpleTextFilterBloc({
    required this.values,
    required this.comparator,
    this.filterText = "",
  }) : super(SimpleTextFilterState(values: values)) {
    _dispatch();
  }

  final String Function(T) comparator;

  final List<T> values;
  String filterText;

  void _dispatch() {
    on<SimpleTextFilterEvent<T>>((event, emit) async {
      event.when(
        updateFilter: (String filter) {
          filterText = filter.toLowerCase();
          _filter(emit);
        },
        receiveNewValues: (List<T> newValues) {
          values
            ..clear()
            ..addAll(newValues);
          _filter(emit);
        },
      );
    });
  }

  void _filter(Emitter<SimpleTextFilterState<T>> emit) {
    final List<T> result = [...values];

    result.retainWhere((value) {
      if (filterText.isNotEmpty) {
        return comparator(value).toLowerCase().contains(filterText);
      }
      return true;
    });

    emit(SimpleTextFilterState(values: result));
  }
}

@freezed
class SimpleTextFilterEvent<T> with _$SimpleTextFilterEvent<T> {
  const factory SimpleTextFilterEvent.updateFilter(String filter) =
      _UpdateFilter;
  const factory SimpleTextFilterEvent.receiveNewValues(List<T> newValues) =
      _ReceiveNewValues<T>;
}

@freezed
class SimpleTextFilterState<T> with _$SimpleTextFilterState<T> {
  const factory SimpleTextFilterState({
    required List<T> values,
  }) = _SimpleTextFilterState<T>;
}
