import 'dart:io';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'share_bloc.freezed.dart';

class DocShareBloc extends Bloc<DocShareEvent, DocShareState> {
  DocShareBloc({
    required this.view,
  }) : super(const DocShareState.initial()) {
    on<ShareMarkdown>(_onShareMarkdown);
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
          (error) => right(error),
          (markdown) => left(_saveMarkdownToPath(markdown, event.path)),
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
class DocShareEvent with _$DocShareEvent {
  const factory DocShareEvent.shareMarkdown(String path) = ShareMarkdown;
  const factory DocShareEvent.shareText() = ShareText;
  const factory DocShareEvent.shareLink() = ShareLink;
}

@freezed
class DocShareState with _$DocShareState {
  const factory DocShareState.initial() = _Initial;
  const factory DocShareState.loading() = _Loading;
  const factory DocShareState.finish(
    Either<ExportDataPB, FlowyError> successOrFail,
  ) = _Finish;
}
