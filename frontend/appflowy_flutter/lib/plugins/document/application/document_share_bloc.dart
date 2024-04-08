import 'dart:io';

import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_share_bloc.freezed.dart';

class DocumentShareBloc extends Bloc<DocumentShareEvent, DocumentShareState> {
  DocumentShareBloc({required this.view})
      : super(const DocumentShareState.initial()) {
    on<ShareMarkdown>(_onShareMarkdown);
  }

  final ViewPB view;

  Future<void> _onShareMarkdown(
    ShareMarkdown event,
    Emitter<DocumentShareState> emit,
  ) async {
    emit(const DocumentShareState.loading());

    final documentExporter = DocumentExporter(view);
    final result = await documentExporter.export(DocumentExportType.markdown);
    emit(
      DocumentShareState.finish(
        result.fold(
          (markdown) =>
              FlowyResult.success(_saveMarkdownToPath(markdown, event.path)),
          (error) => FlowyResult.failure(error),
        ),
      ),
    );
  }

  ExportDataPB _saveMarkdownToPath(String markdown, String path) {
    File(path).writeAsStringSync(markdown);
    return ExportDataPB()
      ..data = markdown
      ..exportType = ExportType.Markdown;
  }
}

@freezed
class DocumentShareEvent with _$DocumentShareEvent {
  const factory DocumentShareEvent.shareMarkdown(String path) = ShareMarkdown;
  const factory DocumentShareEvent.shareText() = ShareText;
  const factory DocumentShareEvent.shareLink() = ShareLink;
}

@freezed
class DocumentShareState with _$DocumentShareState {
  const factory DocumentShareState.initial() = _Initial;
  const factory DocumentShareState.loading() = _Loading;
  const factory DocumentShareState.finish(
    FlowyResult<ExportDataPB, FlowyError> successOrFail,
  ) = _Finish;
}
