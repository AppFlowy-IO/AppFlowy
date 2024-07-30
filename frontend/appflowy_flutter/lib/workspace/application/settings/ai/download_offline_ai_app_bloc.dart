import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
part 'download_offline_ai_app_bloc.freezed.dart';

class DownloadOfflineAIBloc
    extends Bloc<DownloadOfflineAIEvent, DownloadOfflineAIState> {
  DownloadOfflineAIBloc() : super(const DownloadOfflineAIState()) {
    on<DownloadOfflineAIEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    DownloadOfflineAIEvent event,
    Emitter<DownloadOfflineAIState> emit,
  ) async {
    await event.when(
      started: () async {
        final result = await ChatEventGetOfflineAIAppLink().send();
        await result.fold(
          (app) async {
            await launchUrl(Uri.parse(app.link));
          },
          (err) {},
        );
      },
    );
  }
}

@freezed
class DownloadOfflineAIEvent with _$DownloadOfflineAIEvent {
  const factory DownloadOfflineAIEvent.started() = _Started;
}

@freezed
class DownloadOfflineAIState with _$DownloadOfflineAIState {
  const factory DownloadOfflineAIState() = _DownloadOfflineAIState;
}
