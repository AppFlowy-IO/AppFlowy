import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mobile_view_page_bloc.freezed.dart';

class MobileViewPageBloc
    extends Bloc<MobileViewPageEvent, MobileViewPageState> {
  MobileViewPageBloc({
    required this.viewId,
  })  : _viewListener = ViewListener(viewId: viewId),
        super(MobileViewPageState.initial()) {
    on<MobileViewPageEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _registerListeners();

            final result = await ViewBackendService.getView(viewId);
            final isImmersiveMode =
                _isImmersiveMode(result.fold((s) => s, (f) => null));
            emit(
              state.copyWith(
                isLoading: false,
                result: result,
                isImmersiveMode: isImmersiveMode,
              ),
            );
          },
          updateImmersionMode: (isImmersiveMode) {
            emit(
              state.copyWith(
                isImmersiveMode: isImmersiveMode,
              ),
            );
          },
        );
      },
    );
  }

  final String viewId;
  final ViewListener _viewListener;

  @override
  Future<void> close() {
    _viewListener.stop();
    return super.close();
  }

  void _registerListeners() {
    _viewListener.start(
      onViewUpdated: (view) {
        final isImmersiveMode = _isImmersiveMode(view);
        add(MobileViewPageEvent.updateImmersionMode(isImmersiveMode));
      },
    );
  }

  // only the document page supports immersive mode (version 0.5.6)
  bool _isImmersiveMode(ViewPB? view) {
    if (view == null) {
      return false;
    }

    final cover = view.cover;
    if (cover == null || cover.type == PageStyleCoverImageType.none) {
      return false;
    } else if (view.layout == ViewLayoutPB.Document && !cover.isPresets) {
      // only support immersive mode for document layout
      return true;
    }

    return false;
  }
}

@freezed
class MobileViewPageEvent with _$MobileViewPageEvent {
  const factory MobileViewPageEvent.initial() = Initial;
  const factory MobileViewPageEvent.updateImmersionMode(bool isImmersiveMode) =
      UpdateImmersionMode;
}

@freezed
class MobileViewPageState with _$MobileViewPageState {
  const factory MobileViewPageState({
    @Default(true) bool isLoading,
    @Default(null) FlowyResult<ViewPB, FlowyError>? result,
    @Default(false) bool isImmersiveMode,
  }) = _MobileViewPageState;

  factory MobileViewPageState.initial() => const MobileViewPageState();
}
