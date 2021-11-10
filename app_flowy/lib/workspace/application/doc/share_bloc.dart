import 'package:app_flowy/workspace/domain/i_share.dart';
import 'package:app_flowy/workspace/infrastructure/markdown/delta_markdown.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/export.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
part 'share_bloc.freezed.dart';

class DocShareBloc extends Bloc<DocShareEvent, DocShareState> {
  IShare shareManager;
  View view;
  DocShareBloc({required this.view, required this.shareManager}) : super(const DocShareState.initial()) {
    on<DocShareEvent>((event, emit) async {
      await event.map(
        shareMarkdown: (ShareMarkdown value) async {
          await shareManager.exportMarkdown(view.id).then((result) {
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
  const factory DocShareState.finish(Either<ExportData, WorkspaceError> successOrFail) = _Finish;
}
