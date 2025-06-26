import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/repositories/mention_repository.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'person_event.dart';
export 'person_event.dart';
import 'person_state.dart';
export 'person_state.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  PersonBloc({
    required this.documentId,
    required this.personId,
    required this.repository,
    required this.workspaceId,
    required this.personListCache,
  }) : super(PersonState.initial()) {
    on<InitialEvent>(_onInitial);
    on<UpdatePersonEvent>(_onUpdatePerson);
  }
  final String documentId;
  final String personId;
  final String workspaceId;
  final MentionRepository repository;
  final PersonListCache personListCache;

  Future<void> _onInitial(
    InitialEvent event,
    Emitter<PersonState> emit,
  ) async {
    final persons = personListCache.getPersons(workspaceId) ?? [];
    final localPerson = persons.where((p) => p.id == personId).firstOrNull;
    if (localPerson != null) {
      add(PersonEvent.updatePerson(localPerson));
    }
    final result = await repository.getPerson(
      documentId: documentId,
      personId: personId,
      workspaceId: workspaceId,
    );

    result.fold((t) {
      emit(state.copyWith(person: t.person, access: t.access));
      personListCache.updatePerson(workspaceId, t.person);
    }, (e) {
      emit(state.copyWith(getPersonFailedMesssage: e.msg));
      Log.error('Error fetching person: $e');
    });
  }

  Future<void> _onUpdatePerson(
    UpdatePersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(state.copyWith(person: event.person));
  }
}
