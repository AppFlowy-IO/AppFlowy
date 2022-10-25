import 'dart:convert';
import 'dart:io';
import 'package:app_flowy/plugins/doc/application/share_service.dart';
import 'package:app_flowy/workspace/application/markdown/document_markdown.dart';
import 'package:flowy_sdk/protobuf/flowy-document/entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_editor/appflowy_editor.dart' show Document;
part 'share_bloc.freezed.dart';

class DocShareBloc extends Bloc<DocShareEvent, DocShareState> {
  ShareService service;
  ViewPB view;
  DocShareBloc({required this.view, required this.service})
      : super(const DocShareState.initial()) {
    on<DocShareEvent>((event, emit) async {
      await event.map(
        shareMarkdown: (ShareMarkdown shareMarkdown) async {
          await service.exportMarkdown(view).then((result) {
            result.fold(
              (value) => emit(
                DocShareState.finish(
                  left(_saveMarkdown(value, shareMarkdown.path)),
                ),
              ),
              (error) => emit(DocShareState.finish(right(error))),
            );
          });

          emit(const DocShareState.loading());
        },
        shareLink: (ShareLink value) {},
        shareText: (ShareText value) {},
      );
    });
  }

  ExportDataPB _saveMarkdown(ExportDataPB value, String path) {
    final markdown = _convertDocumentToMarkdown(value);
    value.data = markdown;
    File(path).writeAsStringSync(markdown);
    return value;
  }

  String _convertDocumentToMarkdown(ExportDataPB value) {
    final json = jsonDecode(value.data);
    final document = Document.fromJson(json);
    return documentToMarkdown(document);
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
      Either<ExportDataPB, FlowyError> successOrFail) = _Finish;
}
