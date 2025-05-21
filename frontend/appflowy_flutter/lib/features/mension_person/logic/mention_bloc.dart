import 'package:appflowy/features/mension_person/data/models/models.dart';
import 'package:appflowy/features/mension_person/data/repositories/mention_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_bloc.freezed.dart';

class MentionBloc extends Bloc<MentionEvent, MentionState> {
  MentionBloc(this.repository, this.workspaceId)
      : super(MentionState.initial()) {
    on<Initial>(_onInitial);
    on<GetMembers>(_onGetMembers);
  }
  final MentionRepository repository;
  final String workspaceId;

  Future<void> _onInitial(
    Initial event,
    Emitter<MentionState> emit,
  ) async {}

  Future<void> _onGetMembers(
    GetMembers event,
    Emitter<MentionState> emit,
  ) async {}
}

@freezed
class MentionEvent with _$MentionEvent {
  const factory MentionEvent.init() = Initial;

  /// Loads the shared users for the page.
  const factory MentionEvent.getMembers({required String workspaceId}) =
      GetMembers;
}

@freezed
class MentionState with _$MentionState {
  const factory MentionState({
    @Default([]) List<Member> members,
    @Default(false) bool sendNotification,
    @Default(null) String? focusId,
    @Default(false) bool showMoreMember,
    @Default(false) bool showMorePage,
  }) = _MentionState;

  factory MentionState.initial() => const MentionState();
}
