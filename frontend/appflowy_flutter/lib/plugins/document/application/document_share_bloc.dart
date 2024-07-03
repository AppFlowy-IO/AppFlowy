import 'dart:io';

import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_share_bloc.freezed.dart';

// todo: replace with beta
const _url = 'https://beta.appflowy.com';

class DocumentShareBloc extends Bloc<DocumentShareEvent, DocumentShareState> {
  DocumentShareBloc({
    required this.view,
  }) : super(DocumentShareState.initial()) {
    on<DocumentShareEvent>((event, emit) async {
      await event.when(
        initial: () async {
          viewListener = ViewListener(viewId: view.id)
            ..start(
              onViewUpdated: (value) {
                add(DocumentShareEvent.updateViewName(value.name));
              },
            );

          final publishInfo = await ViewBackendService.getPublishInfo(view);
          publishInfo.fold((s) {
            emit(
              state.copyWith(
                isPublished: true,
                url: '$_url/${s.namespace}/${s.publishName}',
                viewName: view.name,
              ),
            );
          }, (f) {
            emit(
              state.copyWith(
                isPublished: false,
                url: '',
                viewName: view.name,
              ),
            );
          });
        },
        share: (type, path) async {
          if (DocumentShareType.unimplemented.contains(type)) {
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
        },
        publish: (nameSpace, publishName) async {
          // set space name
          try {
            final result =
                await ViewBackendService.getPublishNameSpace().getOrThrow();

            await ViewBackendService.publish(
              view,
              name: publishName,
            ).getOrThrow();

            emit(
              state.copyWith(
                isPublished: true,
                publishResult: FlowySuccess(null),
                unpublishResult: null,
                url: '$_url/${result.namespace}/$publishName',
              ),
            );
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
        },
        unPublish: () async {
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
        },
        updateViewName: (viewName) async {
          emit(state.copyWith(viewName: viewName));
        },
      );
    });
  }

  final ViewPB view;
  late final ViewListener viewListener;

  late final exporter = DocumentExporter(view);

  @override
  Future<void> close() async {
    await viewListener.stop();
    return super.close();
  }

  Future<FlowyResult<ExportDataPB, FlowyError>> _export(
    DocumentShareType type,
    String? path,
  ) async {
    final result = await exporter.export(type.exportType);
    return result.fold(
      (s) {
        if (path != null) {
          switch (type) {
            case DocumentShareType.markdown:
              return FlowySuccess(_saveMarkdownToPath(s, path));
            case DocumentShareType.html:
              return FlowySuccess(_saveHTMLToPath(s, path));
            default:
              break;
          }
        }
        return FlowyResult.failure(FlowyError());
      },
      (f) => FlowyResult.failure(f),
    );
  }

  ExportDataPB _saveMarkdownToPath(String markdown, String path) {
    File(path).writeAsStringSync(markdown);
    return ExportDataPB()
      ..data = markdown
      ..exportType = ExportType.Markdown;
  }

  ExportDataPB _saveHTMLToPath(String html, String path) {
    File(path).writeAsStringSync(html);
    return ExportDataPB()
      ..data = html
      ..exportType = ExportType.HTML;
  }
}

enum DocumentShareType {
  markdown,
  html,
  text,
  link;

  static List<DocumentShareType> get unimplemented => [text, link];

  DocumentExportType get exportType {
    switch (this) {
      case DocumentShareType.markdown:
        return DocumentExportType.markdown;
      case DocumentShareType.html:
        return DocumentExportType.html;
      case DocumentShareType.text:
        return DocumentExportType.text;
      case DocumentShareType.link:
        throw UnsupportedError('DocumentShareType.link is not supported');
    }
  }
}

@freezed
class DocumentShareEvent with _$DocumentShareEvent {
  const factory DocumentShareEvent.initial() = _Initial;
  const factory DocumentShareEvent.share(
    DocumentShareType type,
    String? path,
  ) = _Share;
  const factory DocumentShareEvent.publish(
    String nameSpace,
    String pageId,
  ) = _Publish;
  const factory DocumentShareEvent.unPublish() = _UnPublish;
  const factory DocumentShareEvent.updateViewName(String name) =
      _UpdateViewName;
}

@freezed
class DocumentShareState with _$DocumentShareState {
  const factory DocumentShareState({
    required bool isLoading,
    FlowyResult<ExportDataPB, FlowyError>? exportResult,
    required bool isPublished,
    FlowyResult<void, FlowyError>? publishResult,
    FlowyResult<void, FlowyError>? unpublishResult,
    required String url,
    required String viewName,
  }) = _DocumentShareState;

  factory DocumentShareState.initial() => const DocumentShareState(
        isLoading: false,
        isPublished: false,
        url: '',
        viewName: '',
      );
}
