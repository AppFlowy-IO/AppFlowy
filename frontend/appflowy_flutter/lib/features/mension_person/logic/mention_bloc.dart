import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/repositories/mention_repository.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mention_event.dart';
export 'mention_event.dart';
import 'mention_state.dart';
export 'mention_state.dart';

// bool _showMorePages = false, _showMorePersons = false;

class MentionBloc extends Bloc<MentionEvent, MentionState> {
  MentionBloc({
    required this.repository,
    required this.workspaceId,
    required this.query,
    required this.sendNotification,
    required this.personListCache,
  }) : super(MentionState(sendNotification: sendNotification)) {
    on<Initial>(_onInitial);
    on<Query>(_onQuery);
    on<GetPersons>(_onGetPersons);
    on<UpdatePersonList>(_onUpdatePersonList);
    on<ShowMorePersons>(_onShowMorePersons);
    on<ShowMorePages>(_onShowMorePages);
    on<ToggleSendNotification>(_onToggleSendNotification);
    on<AddVisibleItem>(_onAddVisibleItem);
    on<RemoveVisibleItem>(_onRemoveVisibleItem);
    on<SelectItem>(_onSelectItem);
  }
  final MentionRepository repository;
  final String workspaceId;
  final String query;
  final bool sendNotification;
  final PersonListCache personListCache;

  Future<void> _onInitial(
    Initial event,
    Emitter<MentionState> emit,
  ) async {
    if (!isClosed) {
      emit(
        state.copyWith(
          showMorePersons: false,
          showMorePage: false,
        ),
      );
    }
    if (query.isNotEmpty) {
      add(MentionEvent.query(query));
    }
    add(MentionEvent.getPersons(workspaceId: workspaceId));
  }

  Future<void> _onQuery(
    Query event,
    Emitter<MentionState> emit,
  ) async {
    emit(state.copyWith(query: event.text, selectedId: ''));
    add(MentionEvent.getPersons(workspaceId: workspaceId));
  }

  Future<void> _onGetPersons(
    GetPersons event,
    Emitter<MentionState> emit,
  ) async {
    final localList = personListCache.getPersons(workspaceId) ?? [];
    if (localList.isNotEmpty && state.query.isEmpty) {
      emit(state.copyWith(persons: localList));
    }
    final persons = (await repository.getPersons(
      workspaceId: event.workspaceId,
      query: state.query,
    ))
        .toNullable();
    if (persons == null) return;
    add(MentionEvent.updatePersonList(persons));
    if (persons.isNotEmpty && state.query.isEmpty) {
      personListCache.updatePersonList(workspaceId, persons);
    }
  }

  Future<void> _onUpdatePersonList(
    UpdatePersonList event,
    Emitter<MentionState> emit,
  ) async {
    emit(state.copyWith(persons: event.persons));
  }

  Future<void> _onShowMorePersons(
    ShowMorePersons event,
    Emitter<MentionState> emit,
  ) async {
    emit(state.copyWith(showMorePersons: true, selectedId: event.lastId));
    // _showMorePersons = true;
  }

  Future<void> _onShowMorePages(
    ShowMorePages event,
    Emitter<MentionState> emit,
  ) async {
    emit(state.copyWith(showMorePage: true, selectedId: event.lastId));
    // _showMorePages = true;
  }

  Future<void> _onToggleSendNotification(
    ToggleSendNotification event,
    Emitter<MentionState> emit,
  ) async {
    final value = !state.sendNotification;
    emit(state.copyWith(sendNotification: value));
    await getIt<KeyValueStorage>()
        .setBool(KVKeys.atMenuSendNotification, value);
  }

  Future<void> _onAddVisibleItem(
    AddVisibleItem event,
    Emitter<MentionState> emit,
  ) async {
    final set = Set.of(state.visibleItems);
    set.add(event.id);
    emit(state.copyWith(visibleItems: set));
  }

  Future<void> _onRemoveVisibleItem(
    RemoveVisibleItem event,
    Emitter<MentionState> emit,
  ) async {
    final set = Set.of(state.visibleItems);
    set.remove(event.id);
    emit(state.copyWith(visibleItems: set));
  }

  Future<void> _onSelectItem(
    SelectItem event,
    Emitter<MentionState> emit,
  ) async {
    emit(state.copyWith(selectedId: event.id));
  }
}
