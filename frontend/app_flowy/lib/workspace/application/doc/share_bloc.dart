import 'package:app_flowy/workspace/application/doc/share_service.dart';
import 'package:app_flowy/workspace/application/markdown/delta_markdown.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/share.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'share_bloc.freezed.dart';

class DocShareBloc extends Bloc<DocShareEvent, DocShareState> {
  ShareService service;
  View view;
  DocShareBloc({required this.view, required this.service}) : super(const DocShareState.initial()) {
    on<DocShareEvent>((event, emit) async {
      await event.map(
        shareMarkdown: (ShareMarkdown value) async {
          await service.exportMarkdown(view.id).then((result) {
            result.fold(
              (value) => emit(DocShareState.finish(left(_convertDeltaToMarkdown(value)))),
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

  ExportData _convertDeltaToMarkdown(ExportData value) {
    final result = deltaToMarkdown(value.data);
    value.data = result;
    return value;
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
  const factory DocShareState.finish(Either<ExportData, FlowyError> successOrFail) = _Finish;
}
