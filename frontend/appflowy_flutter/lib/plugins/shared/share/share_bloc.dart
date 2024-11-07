import 'dart:io';

import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/settings/share/export_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'constants.dart';

part 'share_bloc.freezed.dart';

class ShareBloc extends Bloc<ShareEvent, ShareState> {
  ShareBloc({
    required this.view,
  }) : super(ShareState.initial()) {
    on<ShareEvent>((event, emit) async {
      await event.when(
        initial: () async {
          viewListener = ViewListener(viewId: view.id)
            ..start(
              onViewUpdated: (value) {
                add(ShareEvent.updateViewName(value.name, value.id));
              },
              onViewMoveToTrash: (p0) {
                add(const ShareEvent.setPublishStatus(false));
              },
            );

          add(const ShareEvent.updatePublishStatus());
        },
        share: (type, path) async => _share(
          type,
          path,
          emit,
        ),
        publish: (nameSpace, publishName, selectedViewIds) => _publish(
          nameSpace,
          publishName,
          selectedViewIds,
          emit,
        ),
        unPublish: () async => _unpublish(emit),
        updatePublishStatus: () async => _updatePublishStatus(emit),
        updateViewName: (viewName, viewId) async {
          emit(
            state.copyWith(
              viewName: viewName,
              viewId: viewId,
              updatePathNameResult: null,
              publishResult: null,
              unpublishResult: null,
            ),
          );
        },
        setPublishStatus: (isPublished) {
          emit(
            state.copyWith(
              isPublished: isPublished,
              url: isPublished ? state.url : '',
            ),
          );
        },
        updatePathName: (pathName) async => _updatePathName(
          pathName,
          emit,
        ),
      );
    });
  }

  final ViewPB view;
  late final ViewListener viewListener;

  late final documentExporter = DocumentExporter(view);

  @override
  Future<void> close() async {
    await viewListener.stop();
    return super.close();
  }

  Future<void> _share(
    ShareType type,
    String? path,
    Emitter<ShareState> emit,
  ) async {
    if (ShareType.unimplemented.contains(type)) {
      Log.error('DocumentShareType $type is not implemented');
      return;
    }

    emit(state.copyWith(isLoading: true));

    final result = await _export(type, path);

    emit(
      state.copyWith(
        isLoading: false,
        exportResult: result,
      ),
    );
  }

  Future<void> _publish(
    String nameSpace,
    String publishName,
    List<String> selectedViewIds,
    Emitter<ShareState> emit,
  ) async {
    // set space name
    try {
      final result =
          await ViewBackendService.getPublishNameSpace().getOrThrow();

      await ViewBackendService.publish(
        view,
        name: publishName,
        selectedViewIds: selectedViewIds,
      ).getOrThrow();

      emit(
        state.copyWith(
          isPublished: true,
          publishResult: FlowySuccess(null),
          unpublishResult: null,
          namespace: result.namespace,
          pathName: publishName,
          url: ShareConstants.buildPublishUrl(
            nameSpace: result.namespace,
            publishName: publishName,
          ),
        ),
      );

      Log.info('publish success: ${result.namespace}/$publishName');
    } catch (e) {
      Log.error('publish error: $e');

      emit(
        state.copyWith(
          isPublished: false,
          publishResult: FlowyResult.failure(
            FlowyError(msg: 'publish error: $e'),
          ),
          unpublishResult: null,
          url: '',
        ),
      );
    }
  }

  Future<void> _unpublish(Emitter<ShareState> emit) async {
    emit(
      state.copyWith(
        publishResult: null,
        unpublishResult: null,
      ),
    );

    final result = await ViewBackendService.unpublish(view);
    final isPublished = !result.isSuccess;
    result.onFailure((f) {
      Log.error('unpublish error: $f');
    });

    emit(
      state.copyWith(
        isPublished: isPublished,
        publishResult: null,
        unpublishResult: result,
        url: result.fold((_) => '', (_) => state.url),
      ),
    );
  }

  Future<void> _updatePublishStatus(Emitter<ShareState> emit) async {
    final publishInfo = await ViewBackendService.getPublishInfo(view);
    final enablePublish = await UserBackendService.getCurrentUserProfile().fold(
      (v) => v.authenticator == AuthenticatorPB.AppFlowyCloud,
      (p) => false,
    );
    String workspaceId = state.workspaceId;
    if (workspaceId.isEmpty) {
      workspaceId = await UserBackendService.getCurrentWorkspace()
          .fold((s) => s.id, (f) => '');
    }
    publishInfo.fold((s) {
      emit(
        state.copyWith(
          isPublished: true,
          namespace: s.namespace,
          pathName: s.publishName,
          url: ShareConstants.buildPublishUrl(
            nameSpace: s.namespace,
            publishName: s.publishName,
          ),
          viewName: view.name,
          enablePublish: enablePublish,
          workspaceId: workspaceId,
          viewId: view.id,
        ),
      );
    }, (f) {
      emit(
        state.copyWith(
          isPublished: false,
          url: '',
          viewName: view.name,
          enablePublish: enablePublish,
          workspaceId: workspaceId,
          viewId: view.id,
        ),
      );
    });
  }

  Future<void> _updatePathName(
    String pathName,
    Emitter<ShareState> emit,
  ) async {
    emit(
      state.copyWith(
        updatePathNameResult: null,
      ),
    );
    final request = SetPublishNamePB()
      ..viewId = view.id
      ..newName = pathName;
    final result = await FolderEventSetPublishName(request).send();
    emit(
      state.copyWith(
        updatePathNameResult: result,
        publishResult: null,
        unpublishResult: null,
        pathName: result.fold(
          (_) => pathName,
          (f) => state.pathName,
        ),
        url: result.fold(
          (s) => ShareConstants.buildPublishUrl(
            nameSpace: state.namespace,
            publishName: pathName,
          ),
          (f) => state.url,
        ),
      ),
    );
  }

  Future<FlowyResult<ShareType, FlowyError>> _export(
    ShareType type,
    String? path,
  ) async {
    final FlowyResult<String, FlowyError> result;
    if (type == ShareType.csv) {
      final exportResult = await BackendExportService.exportDatabaseAsCSV(
        view.id,
      );
      result = exportResult.fold(
        (s) => FlowyResult.success(s.data),
        (f) => FlowyResult.failure(f),
      );
    } else if (type == ShareType.rawDatabaseData) {
      final exportResult = await BackendExportService.exportDatabaseAsRawData(
        view.id,
      );
      result = exportResult.fold(
        (s) => FlowyResult.success(s.data),
        (f) => FlowyResult.failure(f),
      );
    } else {
      result = await documentExporter.export(type.documentExportType);
    }
    return result.fold(
      (s) {
        if (path != null) {
          switch (type) {
            case ShareType.markdown:
            case ShareType.html:
            case ShareType.csv:
            case ShareType.json:
            case ShareType.rawDatabaseData:
              File(path).writeAsStringSync(s);
              return FlowyResult.success(type);
            default:
              break;
          }
        }
        return FlowyResult.failure(FlowyError());
      },
      (f) => FlowyResult.failure(f),
    );
  }
}

enum ShareType {
  // available in document
  markdown,
  html,
  text,
  link,
  json,

  // only available in database
  csv,
  rawDatabaseData;

  static List<ShareType> get unimplemented => [link];

  DocumentExportType get documentExportType {
    switch (this) {
      case ShareType.markdown:
        return DocumentExportType.markdown;
      case ShareType.html:
        return DocumentExportType.html;
      case ShareType.text:
        return DocumentExportType.text;
      case ShareType.json:
        return DocumentExportType.json;
      case ShareType.csv:
        throw UnsupportedError('DocumentShareType.csv is not supported');
      case ShareType.link:
        throw UnsupportedError('DocumentShareType.link is not supported');
      case ShareType.rawDatabaseData:
        throw UnsupportedError(
          'DocumentShareType.rawDatabaseData is not supported',
        );
    }
  }
}

@freezed
class ShareEvent with _$ShareEvent {
  const factory ShareEvent.initial() = _Initial;
  const factory ShareEvent.share(
    ShareType type,
    String? path,
  ) = _Share;
  const factory ShareEvent.publish(
    String nameSpace,
    String pageId,
    List<String> selectedViewIds,
  ) = _Publish;
  const factory ShareEvent.unPublish() = _UnPublish;
  const factory ShareEvent.updateViewName(String name, String viewId) =
      _UpdateViewName;
  const factory ShareEvent.updatePublishStatus() = _UpdatePublishStatus;
  const factory ShareEvent.setPublishStatus(bool isPublished) =
      _SetPublishStatus;
  const factory ShareEvent.updatePathName(String pathName) = _UpdatePathName;
}

@freezed
class ShareState with _$ShareState {
  const factory ShareState({
    required bool isPublished,
    required bool isLoading,
    required String url,
    required String viewName,
    required bool enablePublish,
    FlowyResult<ShareType, FlowyError>? exportResult,
    FlowyResult<void, FlowyError>? publishResult,
    FlowyResult<void, FlowyError>? unpublishResult,
    FlowyResult<void, FlowyError>? updatePathNameResult,
    required String viewId,
    required String workspaceId,
    required String namespace,
    required String pathName,
  }) = _ShareState;

  factory ShareState.initial() => const ShareState(
        isLoading: false,
        isPublished: false,
        enablePublish: true,
        url: '',
        viewName: '',
        viewId: '',
        workspaceId: '',
        namespace: '',
        pathName: '',
      );
}
