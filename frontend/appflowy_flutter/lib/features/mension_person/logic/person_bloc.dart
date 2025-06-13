import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/data/repositories/mention_repository.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_bloc.freezed.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  PersonBloc({
    required this.documentId,
    required this.personId,
    required this.repository,
    required this.workspaceId,
  }) : super(PersonState.initial()) {
    _personListCache = getIt<PersonListCache>();
    on<Initial>(_onInitial);
    on<UpdatePerson>(_onUpdatePerson);
  }
  final String documentId;
  final String personId;
  final String workspaceId;
  final MentionRepository repository;
  late final PersonListCache _personListCache;

  Future<void> _onInitial(
    Initial event,
    Emitter<PersonState> emit,
  ) async {
    final persons = _personListCache.getPersons(workspaceId) ?? [];
    final localPerson = persons.where((p) => p.id == personId).firstOrNull;
    if (localPerson != null) {
      add(PersonEvent.updatePerson(localPerson));
    }

    (await repository.getPerson(
      documentId: documentId,
      personId: personId,
      workspaceId: workspaceId,
    ))
        .fold((t) {
      emit(state.copyWith(person: t.person, access: t.access));
      _personListCache.updatePerson(workspaceId, t.person);
    }, (e) {
      showToastNotification(
        message: e.msg,
        type: ToastificationType.error,
      );
      Log.error('Error fetching person: $e');
    });
  }

  Future<void> _onUpdatePerson(
    UpdatePerson event,
    Emitter<PersonState> emit,
  ) async {
    emit(state.copyWith(person: event.person));
  }
}

@freezed
class PersonEvent with _$PersonEvent {
  const factory PersonEvent.initial() = Initial;
  const factory PersonEvent.updatePerson(Person person) = UpdatePerson;
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
