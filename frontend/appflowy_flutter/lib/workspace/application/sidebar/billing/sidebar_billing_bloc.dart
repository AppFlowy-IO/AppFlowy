import 'dart:async';

import 'package:appflowy_backend/dispatch/error.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'sidebar_billing_bloc.freezed.dart';

class SidebarBillingBloc
    extends Bloc<SidebarBillingEvent, SidebarBillingState> {
  SidebarBillingBloc() : super(const SidebarBillingState()) {
    _errorListener = ErrorCodeNotifier.add(
      onError: (error) {
        if (!isClosed) {
          add(SidebarBillingEvent.receiveError(error));
        }
      },
      onErrorIf: (errorCode) {
        const relevantErrorCodes = {
          ErrorCode.AIResponseLimitExceeded,
          ErrorCode.FileStorageLimitExceeded,
        };
        return relevantErrorCodes.contains(errorCode);
      },
    );

    on<SidebarBillingEvent>(_handleEvent);
  }

  Future<void> dispose() async {
    if (_errorListener != null) {
      ErrorCodeNotifier.remove(_errorListener!);
    }
  }

  ErrorListener? _errorListener;

  Future<void> _handleEvent(
    SidebarBillingEvent event,
    Emitter<SidebarBillingState> emit,
  ) async {
    await event.when(receiveError: (FlowyError error) async {});
  }
}

@freezed
class SidebarBillingEvent with _$SidebarBillingEvent {
  const factory SidebarBillingEvent.receiveError(FlowyError error) =
      _ReceiveError;
}

@freezed
class SidebarBillingState with _$SidebarBillingState {
  const factory SidebarBillingState({
    FlowyError? error,
    @Default(SidebarBillingPageIndicator.loading())
    SidebarBillingPageIndicator pageIndicator,
  }) = _SidebarBillingState;
}

@freezed
class SidebarBillingPageIndicator with _$SidebarBillingPageIndicator {
  // when start downloading the model
  const factory SidebarBillingPageIndicator.upgradeTier() = _UpgradeTier;
  const factory SidebarBillingPageIndicator.readyToUse() = _ReadyToUse;
  const factory SidebarBillingPageIndicator.loading() = _Loading;
}
