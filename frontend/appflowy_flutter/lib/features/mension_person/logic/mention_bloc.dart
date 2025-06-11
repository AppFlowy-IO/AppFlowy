import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/models/models.dart';
import 'package:appflowy/features/mension_person/data/repositories/mention_repository.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_bloc.freezed.dart';

// bool _showMorePages = false, _showMorePersons = false;

class MentionBloc extends Bloc<MentionEvent, MentionState> {
  MentionBloc(this.repository, this.workspaceId)
      : super(MentionState.initial()) {
    _personListCache = getIt<PersonListCache>();
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
    add(MentionEvent.init());
    add(MentionEvent.getPersons(workspaceId: workspaceId));
  }
  final MentionRepository repository;
  final String workspaceId;
  late final PersonListCache _personListCache;

  Future<void> _onInitial(
    Initial event,
    Emitter<MentionState> emit,
  ) async {
    final sendNotification =
        await getIt<KeyValueStorage>().getBool(KVKeys.atMenuSendNotification) ??
            false;
    if (!isClosed) {
      emit(
        state.copyWith(
          sendNotification: sendNotification,
          showMorePersons: false,
          showMorePage: false,
        ),
      );
    }
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
    final localList = _personListCache.getPersons(workspaceId) ?? [];
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
      _personListCache.updatePersonList(workspaceId, persons);
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

@freezed
class MentionEvent with _$MentionEvent {
  const factory MentionEvent.init() = Initial;
  const factory MentionEvent.getPersons({required String workspaceId}) =
      GetPersons;
  const factory MentionEvent.updatePersonList(List<Person> persons) =
      UpdatePersonList;
  const factory MentionEvent.query(String text) = Query;
  const factory MentionEvent.showMorePersons(String lastId) = ShowMorePersons;
  const factory MentionEvent.showMorePages(String lastId) = ShowMorePages;
  const factory MentionEvent.toggleSendNotification() = ToggleSendNotification;
  const factory MentionEvent.addVisibleItem(String id) = AddVisibleItem;
  const factory MentionEvent.removeVisibleItem(String id) = RemoveVisibleItem;
  const factory MentionEvent.selectItem(String id) = SelectItem;
}

@freezed
class MentionState with _$MentionState {
  const factory MentionState({
    @Default([]) List<Person> persons,
    @Default(false) bool sendNotification,
    @Default(null) String? focusId,
    @Default('') String query,
    @Default('') String selectedId,
    @Default(false) bool showMorePersons,
    @Default(false) bool showMorePage,
    @Default({}) Set<String> visibleItems,
  }) = _MentionState;

  factory MentionState.initial() => const MentionState();
}
