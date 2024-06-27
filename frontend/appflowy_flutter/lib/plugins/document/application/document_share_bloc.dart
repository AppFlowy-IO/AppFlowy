import 'dart:io';

import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_share_bloc.freezed.dart';

const _url = 'https://test.appflowy.io';

class DocumentShareBloc extends Bloc<DocumentShareEvent, DocumentShareState> {
  DocumentShareBloc({
    required this.view,
  }) : super(DocumentShareState.initial()) {
    on<DocumentShareEvent>((event, emit) async {
      await event.when(
        initial: () async {
          final publishInfo = await ViewBackendService.getPublishInfo(view);
          publishInfo.fold((s) {
            emit(
              state.copyWith(
                isPublished: true,
                url: '$_url/${s.namespace}/${s.publishName}',
              ),
            );
          }, (f) {
            emit(state.copyWith(isPublished: false, url: ''));
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
            final getNameSpaceResult =
                await ViewBackendService.getPublishNameSpace();
            final name = await getNameSpaceResult.fold((s) async {
              Log.error('get publish namespace success: ${s.namespace}');
              return s.namespace;
            }, (f) async {
              Log.error('get publish namespace error: $f');
              await ViewBackendService.setPublishNameSpace(nameSpace)
                  .getOrThrow();
              return nameSpace;
            });

            await ViewBackendService.publish(
              view,
              name: publishName,
            ).getOrThrow();

            emit(
              state.copyWith(
                isPublished: true,
                publishResult: FlowySuccess(null),
                url: '$_url/$name/$publishName',
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
                url: '',
              ),
            );
          }
        },
        unPublish: () async {
          await ViewBackendService.unpublish(view);
          emit(
            state.copyWith(
              isPublished: false,
              publishResult: null,
              url: '',
            ),
          );
        },
      );
    });
  }

  final ViewPB view;

  late final exporter = DocumentExporter(view);

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
}

@freezed
class DocumentShareState with _$DocumentShareState {
  const factory DocumentShareState({
    required bool isLoading,
    FlowyResult<ExportDataPB, FlowyError>? exportResult,
    required bool isPublished,
    FlowyResult<void, FlowyError>? publishResult,
    required String url,
  }) = _DocumentShareState;

  factory DocumentShareState.initial() => const DocumentShareState(
        isLoading: false,
        isPublished: false,
        url: '',
      );
}
