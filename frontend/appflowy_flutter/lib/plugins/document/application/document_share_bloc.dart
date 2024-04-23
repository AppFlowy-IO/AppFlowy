import 'dart:io';

import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_share_bloc.freezed.dart';

class DocumentShareBloc extends Bloc<DocumentShareEvent, DocumentShareState> {
  DocumentShareBloc({
    required this.view,
  }) : super(const DocumentShareState.initial()) {
    on<DocumentShareEvent>((event, emit) async {
      await event.when(
        share: (type, path) async {
          if (DocumentShareType.unimplemented.contains(type)) {
            Log.error('DocumentShareType $type is not implemented');
            return;
          }

          emit(const DocumentShareState.loading());

          final exporter = DocumentExporter(view);
          final FlowyResult<ExportDataPB, FlowyError> result =
              await exporter.export(type.exportType).then((value) {
            return value.fold(
              (s) {
                if (path != null) {
                  switch (type) {
                    case DocumentShareType.markdown:
                      return FlowyResult.success(_saveMarkdownToPath(s, path));
                    case DocumentShareType.html:
                      return FlowyResult.success(_saveHTMLToPath(s, path));
                    case DocumentShareType.json:
                      return FlowyResult.success(_saveJSONToPath(s, path));
                    default:
                      break;
                  }
                }
                return FlowyResult.failure(FlowyError());
              },
              (f) => FlowyResult.failure(f),
            );
          });

          emit(DocumentShareState.finish(result));
        },
      );
    });
  }

  final ViewPB view;

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

  ExportDataPB _saveJSONToPath(String json, String path) {
    File(path).writeAsStringSync(json);
    return ExportDataPB()
      ..data = json
      ..exportType = ExportType.Text;
  }
}

enum DocumentShareType {
  markdown,
  html,
  text,
  link,
  // ONLY FOR DEBUG PURPOSES
  json;

  static List<DocumentShareType> get unimplemented => [text, link];

  DocumentExportType get exportType {
    switch (this) {
      case DocumentShareType.markdown:
        return DocumentExportType.markdown;
      case DocumentShareType.html:
        return DocumentExportType.html;
      case DocumentShareType.text:
        return DocumentExportType.text;
      case DocumentShareType.json:
        return DocumentExportType.json;
      case DocumentShareType.link:
        throw UnsupportedError('DocumentShareType.link is not supported');
    }
  }
}

@freezed
class DocumentShareEvent with _$DocumentShareEvent {
  const factory DocumentShareEvent.share(DocumentShareType type, String? path) =
      Share;
}

@freezed
class DocumentShareState with _$DocumentShareState {
  const factory DocumentShareState.initial() = _Initial;
  const factory DocumentShareState.loading() = _Loading;
  const factory DocumentShareState.finish(
    FlowyResult<ExportDataPB, FlowyError> successOrFail,
  ) = _Finish;
}
