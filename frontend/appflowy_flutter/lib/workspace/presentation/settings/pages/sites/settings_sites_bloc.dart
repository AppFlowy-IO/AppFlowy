import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_sites_bloc.freezed.dart';

class SettingsSitesBloc extends Bloc<SettingsSitesEvent, SettingsSitesState> {
  SettingsSitesBloc() : super(const SettingsSitesState()) {
    on<SettingsSitesEvent>((event, emit) async {
      await event.when(
        initial: () async => _initial(emit),
        fetchPublishedViews: () async => _fetchPublishedViews(emit),
        unpublishView: (viewId) async => _unpublishView(
          viewId,
          emit,
        ),
        updateNamespace: (namespace) async => _updateNamespace(
          namespace,
          emit,
        ),
        updatePublishName: (name) async => _updatePublishName(
          name,
          emit,
        ),
      );
    });
  }

  Future<void> _initial(Emitter<SettingsSitesState> emit) async {
    await _fetchPublishedViews(emit);
    await _fetchPublishNamespace(emit);
  }

  Future<void> _fetchPublishNamespace(Emitter<SettingsSitesState> emit) async {
    emit(
      state.copyWith(
        actionResult: SettingsSitesActionResult.none(),
      ),
    );

    final result = await FolderEventGetPublishNamespace().send();

    emit(
      state.copyWith(
        namespace: result.fold((s) => s.namespace, (_) => ''),
      ),
    );
  }

  Future<void> _fetchPublishedViews(Emitter<SettingsSitesState> emit) async {
    emit(
      state.copyWith(
        actionResult: SettingsSitesActionResult.none(),
      ),
    );

    // final result = await FolderEventListPublishedViews().send();

    emit(
      state.copyWith(
        // publishedViews: result.fold((s) => s.items, (_) => []),
        publishedViews: SettingsPageSitesConstants.fakeData,
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.fetchPublishedViews,
          isLoading: false,
          result: null,
        ),
      ),
    );
  }

  Future<void> _unpublishView(
    String viewId,
    Emitter<SettingsSitesState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.unpublishView,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final request = UnpublishViewsPayloadPB(viewIds: [viewId]);
    final result = await FolderEventUnpublishViews(request).send();
    final publishedViews = result.fold(
      (_) => state.publishedViews
          .where((view) => view.info.viewId != viewId)
          .toList(),
      (_) => state.publishedViews,
    );

    emit(
      state.copyWith(
        publishedViews: publishedViews,
        actionResult: SettingsSitesActionResult(
          actionType: SettingsSitesActionType.unpublishView,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _updateNamespace(
    String namespace,
    Emitter<SettingsSitesState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.updateNamespace,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final request = SetPublishNamespacePayloadPB()..newNamespace = namespace;
    final result = await FolderEventSetPublishNamespace(request).send();

    emit(
      state.copyWith(
        actionResult: SettingsSitesActionResult(
          actionType: SettingsSitesActionType.updateNamespace,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _updatePublishName(
    String name,
    Emitter<SettingsSitesState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.updatePublishName,
          isLoading: true,
          result: null,
        ),
      ),
    );

    // todo: not implemented.
  }
}

@freezed
class SettingsSitesState with _$SettingsSitesState {
  const factory SettingsSitesState({
    @Default([]) List<PublishInfoViewPB> publishedViews,
    SettingsSitesActionResult? actionResult,
    @Default('') String namespace,
  }) = _SettingsSitesState;

  factory SettingsSitesState.initial() => const SettingsSitesState();
}

@freezed
class SettingsSitesEvent with _$SettingsSitesEvent {
  const factory SettingsSitesEvent.initial() = _Initial;
  const factory SettingsSitesEvent.fetchPublishedViews() = _FetchPublishedViews;
  const factory SettingsSitesEvent.unpublishView(String viewId) =
      _UnpublishView;
  const factory SettingsSitesEvent.updateNamespace(String namespace) =
      _UpdateNamespace;
  const factory SettingsSitesEvent.updatePublishName(String name) =
      _UpdatePublishName;
}

enum SettingsSitesActionType {
  none,
  unpublishView,
  updateNamespace,
  fetchPublishedViews,
  updatePublishName,
}

class SettingsSitesActionResult {
  const SettingsSitesActionResult({
    required this.actionType,
    required this.isLoading,
    required this.result,
  });

  factory SettingsSitesActionResult.none() => const SettingsSitesActionResult(
        actionType: SettingsSitesActionType.none,
        isLoading: false,
        result: null,
      );

  final SettingsSitesActionType actionType;
  final FlowyResult<void, FlowyError>? result;
  final bool isLoading;

  @override
  String toString() {
    return 'SettingsSitesActionResult(actionType: $actionType, isLoading: $isLoading, result: $result)';
  }
}
