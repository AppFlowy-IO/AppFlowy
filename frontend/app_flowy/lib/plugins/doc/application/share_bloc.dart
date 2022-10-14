import 'dart:async';
import 'dart:io';
import 'package:app_flowy/startup/tasks/rust_sdk.dart';
import 'package:app_flowy/workspace/application/markdown/delta_markdown.dart';
import 'package:app_flowy/plugins/doc/application/share_service.dart';
import 'package:flowy_sdk/protobuf/flowy-document/entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'share_bloc.freezed.dart';

class DocShareBloc extends Bloc<DocShareEvent, DocShareState> {
  ShareService service;
  ViewPB view;
  DocShareBloc({required this.view, required this.service})
      : super(const DocShareState.initial()) {
    on<DocShareEvent>((event, emit) async {
      await event.map(
        shareMarkdown: (ShareMarkdown value) async {
          await service.exportMarkdown(view.id).then((result) {
            result.fold(
              (value) => emit(
                  DocShareState.finish(left(_convertDeltaToMarkdown(value)))),
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

  ExportDataPB _convertDeltaToMarkdown(ExportDataPB value) {
    final result = deltaToMarkdown(value.data);
    value.data = result;
    writeFile(result);
    return value;
  }

  Future<Directory> get _exportDir async {
    Directory documentsDir = await appFlowyDocumentDirectory();

    return documentsDir;
  }

  Future<String> get _localPath async {
    final dir = await _exportDir;
    return dir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/${view.name}.md');
  }

  Future<File> writeFile(String md) async {
    final file = await _localFile;
    return file.writeAsString(md);
  }
}

@freezed
class DocShareEvent with _$DocShareEvent {
  const factory DocShareEvent.shareMarkdown() = ShareMarkdown;
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
