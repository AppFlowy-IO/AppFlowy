import 'dart:io';

import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_bloc.freezed.dart';

class DocShareBloc extends Bloc<DocShareEvent, DocShareState> {
  DocShareBloc({required this.view}) : super(const DocShareState.initial()) {
    on<ShareMarkdown>(_onShareMarkdown);
    on<ShareHTML>(_onShareHTML);
  }

  final ViewPB view;

  Future<void> _onShareMarkdown(
    ShareMarkdown event,
    Emitter<DocShareState> emit,
  ) async {
    emit(const DocShareState.loading());

    final documentExporter = DocumentExporter(view);
    final result = await documentExporter.export(DocumentExportType.markdown);
    emit(
      DocShareState.finish(
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

  Future<void> _onShareHTML(
    ShareHTML event,
    Emitter<DocShareState> emit,
  ) async {
    emit(const DocShareState.loading());

    final documentExporter = DocumentExporter(view);
    final result = await documentExporter.export(DocumentExportType.html);
    emit(
      DocShareState.finish(
        result.fold(
          (html) =>
              FlowyResult.success(_saveHTMLToPath(html, event.path)),
          (error) => FlowyResult.failure(error),
        ),
      ),
    );
  }

  ExportDataPB _saveHTMLToPath(String html, String path) {
    File(path).writeAsStringSync(html);
    return ExportDataPB()
      ..data = html
      ..exportType = ExportType.HTML;
  }
}

@freezed
class DocShareEvent with _$DocShareEvent {
  const factory DocShareEvent.shareMarkdown(String path) = ShareMarkdown;
  const factory DocShareEvent.shareHTML(String path) = ShareHTML;
  const factory DocShareEvent.shareText() = ShareText;
  const factory DocShareEvent.shareLink() = ShareLink;
}

@freezed
class DocShareState with _$DocShareState {
  const factory DocShareState.initial() = _Initial;
  const factory DocShareState.loading() = _Loading;
  const factory DocShareState.finish(
    FlowyResult<ExportDataPB, FlowyError> successOrFail,
  ) = _Finish;
}
