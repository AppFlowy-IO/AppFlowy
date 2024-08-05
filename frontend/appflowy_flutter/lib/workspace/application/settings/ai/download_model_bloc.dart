import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fixnum/fixnum.dart';
part 'download_model_bloc.freezed.dart';

class DownloadModelBloc extends Bloc<DownloadModelEvent, DownloadModelState> {
  DownloadModelBloc(LLMModelPB model)
      : super(DownloadModelState(model: model)) {
    on<DownloadModelEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    DownloadModelEvent event,
    Emitter<DownloadModelState> emit,
  ) async {
    await event.when(
      started: () async {
        final downloadStream = DownloadingStream();
        downloadStream.listen(
          onModelPercentage: (name, percent) {
            if (!isClosed) {
              add(
                DownloadModelEvent.updatePercent(name, percent),
              );
            }
          },
          onPluginPercentage: (percent) {
            if (!isClosed) {
              add(DownloadModelEvent.updatePercent("AppFlowy Plugin", percent));
            }
          },
          onFinish: () {
            add(const DownloadModelEvent.downloadFinish());
          },
          onError: (err) {
            Log.error(err);
          },
        );

        final payload =
            DownloadLLMPB(progressStream: Int64(downloadStream.nativePort));
        final result = await AIEventDownloadLLMResource(payload).send();
        result.fold((_) {
          emit(
            state.copyWith(
              downloadStream: downloadStream,
              loadingState: const LoadingState.finish(),
              downloadError: null,
            ),
          );
        }, (err) {
          emit(state.copyWith(loadingState: LoadingState.finish(error: err)));
        });
      },
      updatePercent: (String object, double percent) {
        emit(state.copyWith(object: object, percent: percent));
      },
      downloadFinish: () {
        emit(state.copyWith(isFinish: true));
      },
    );
  }

  @override
  Future<void> close() async {
    await state.downloadStream?.dispose();
    return super.close();
  }
}

@freezed
class DownloadModelEvent with _$DownloadModelEvent {
  const factory DownloadModelEvent.started() = _Started;
  const factory DownloadModelEvent.updatePercent(
    String object,
    double percent,
  ) = _UpdatePercent;
  const factory DownloadModelEvent.downloadFinish() = _DownloadFinish;
}

@freezed
class DownloadModelState with _$DownloadModelState {
  const factory DownloadModelState({
    required LLMModelPB model,
    DownloadingStream? downloadStream,
    String? downloadError,
    @Default("") String object,
    @Default(0) double percent,
    @Default(false) bool isFinish,
    @Default(LoadingState.loading()) LoadingState loadingState,
  }) = _DownloadModelState;
}

class DownloadingStream {
  DownloadingStream() {
    _port.handler = _controller.add;
  }

  final RawReceivePort _port = RawReceivePort();
  StreamSubscription<String>? _sub;
  final StreamController<String> _controller = StreamController.broadcast();
  int get nativePort => _port.sendPort.nativePort;

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
    _port.close();
  }

  void listen({
    void Function(String modelName, double percent)? onModelPercentage,
    void Function(double percent)? onPluginPercentage,
    void Function(String data)? onError,
    void Function()? onFinish,
  }) {
    _sub = _controller.stream.listen((text) {
      if (text.contains(':progress:')) {
        final progressIndex = text.indexOf(':progress:');
        final modelName = text.substring(0, progressIndex);
        final progressValue = text
            .substring(progressIndex + 10); // 10 is the length of ":progress:"
        final percent = double.tryParse(progressValue);
        if (percent != null) {
          onModelPercentage?.call(modelName, percent);
        }
      } else if (text.startsWith('plugin:progress:')) {
        final percent = double.tryParse(text.substring(16));
        if (percent != null) {
          onPluginPercentage?.call(percent);
        }
      } else if (text.startsWith('finish')) {
        onFinish?.call();
      } else if (text.startsWith('error:')) {
        // substring 6 to remove "error:"
        onError?.call(text.substring(6));
      }
    });
  }
}
