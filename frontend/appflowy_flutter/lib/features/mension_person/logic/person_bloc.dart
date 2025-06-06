import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/data/repositories/person_repository.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_bloc.freezed.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  PersonBloc({
    required this.documentId,
    required this.personId,
    required this.repository,
  }) : super(PersonState.initial()) {
    on<Initial>(_onInitial);
  }
  final String documentId;
  final String personId;
  final PersonRepository repository;

  Future<void> _onInitial(
    Initial event,
    Emitter<PersonState> emit,
  ) async {
    (await repository.getPerson(
      documentId: documentId,
      personId: personId,
    ))
        .fold((t) {
      emit(state.copyWith(person: t.person, access: t.access));
    }, (e) {
      Log.error('Error fetching person: $e');
    });
  }
}

@freezed
class PersonEvent with _$PersonEvent {
  const factory PersonEvent.initial() = Initial;
}

@freezed
class PersonState with _$PersonState {
  const factory PersonState({
    @Default(null) Person? person,
    @Default(null) String? documentId,
    @Default(false) bool access,
  }) = _PersonState;

  factory PersonState.initial() => const PersonState();
}
