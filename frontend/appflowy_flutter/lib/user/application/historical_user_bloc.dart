import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'historical_user_bloc.freezed.dart';

class HistoricalUserBloc
    extends Bloc<HistoricalUserEvent, HistoricalUserState> {
  HistoricalUserBloc() : super(HistoricalUserState.initial()) {
    on<HistoricalUserEvent>((event, emit) async {
      await event.when(
        initial: () async {
          await _loadHistoricalUsers();
        },
        didLoadHistoricalUsers: (List<HistoricalUserPB> historicalUsers) {
          emit(state.copyWith(historicalUsers: historicalUsers));
        },
        openHistoricalUser: (HistoricalUserPB historicalUser) async {
          await UserBackendService.openHistoricalUser(historicalUser);
          emit(state.copyWith(openedHistoricalUser: historicalUser));
        },
      );
    });
  }

  Future<void> _loadHistoricalUsers() async {
    final result = await UserBackendService.loadHistoricalUsers();
    result.fold(
      (historicalUsers) {
        historicalUsers
            .retainWhere((element) => element.authType == AuthTypePB.Local);
        add(HistoricalUserEvent.didLoadHistoricalUsers(historicalUsers));
      },
      (error) => Log.error(error),
    );
  }
}

@freezed
class HistoricalUserEvent with _$HistoricalUserEvent {
  const factory HistoricalUserEvent.initial() = _Initial;
  const factory HistoricalUserEvent.didLoadHistoricalUsers(
    List<HistoricalUserPB> historicalUsers,
  ) = _DidLoadHistoricalUsers;
  const factory HistoricalUserEvent.openHistoricalUser(
    HistoricalUserPB historicalUser,
  ) = _OpenHistoricalUser;
}

@freezed
class HistoricalUserState with _$HistoricalUserState {
  const factory HistoricalUserState({
    required List<HistoricalUserPB> historicalUsers,
    required HistoricalUserPB? openedHistoricalUser,
  }) = _HistoricalUserState;

  factory HistoricalUserState.initial() => const HistoricalUserState(
        historicalUsers: [],
        openedHistoricalUser: null,
      );
}
