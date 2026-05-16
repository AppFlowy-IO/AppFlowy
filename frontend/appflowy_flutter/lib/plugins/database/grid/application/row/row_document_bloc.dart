import 'package:flutter/foundation.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/row/row_service.dart';

part 'row_document_bloc.freezed.dart';

class RowDocumentBloc extends Bloc<RowDocumentEvent, RowDocumentState> {
  RowDocumentBloc({
    required this.rowId,
    required String viewId,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        super(RowDocumentState.initial()) {
    _dispatch();
  }

  final String rowId;
  final RowBackendService _rowBackendSvc;

  void _dispatch() {
    on<RowDocumentEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _getRowDocumentView();
          },
          didReceiveRowDocument: (view) {
            emit(
              state.copyWith(
                viewPB: view,
                loadingState: const LoadingState.finish(),
              ),
            );
          },
          didReceiveError: (FlowyError error) {
            emit(
              state.copyWith(
                loadingState: LoadingState.error(error),
              ),
            );
          },
          updateIsEmpty: (isEmpty) async {
            final unitOrFailure = await _rowBackendSvc.updateMeta(
              rowId: rowId,
              isDocumentEmpty: isEmpty,
            );

            unitOrFailure.fold((l) => null, (err) => Log.error(err));
          },
        );
      },
    );
  }

  Future<void> _getRowDocumentView() async {
    final rowDetailOrError = await _rowBackendSvc.getRowMeta(rowId);
    rowDetailOrError.fold(
      (RowMetaPB rowMeta) async {
        final viewsOrError =
            await ViewBackendService.getView(rowMeta.documentId);

        if (isClosed) {
          return;
        }

        viewsOrError.fold(
          (view) => add(RowDocumentEvent.didReceiveRowDocument(view)),
          (error) async {
            if (error.code == ErrorCode.RecordNotFound) {
              // By default, the document of the row is not exist. So creating a
              // new document for the given document id of the row.
              final documentView =
                  await _createRowDocumentView(rowMeta.documentId);
              if (documentView != null && !isClosed) {
                add(RowDocumentEvent.didReceiveRowDocument(documentView));
              }
            } else {
              add(RowDocumentEvent.didReceiveError(error));
            }
          },
        );
      },
      (err) => Log.error('Failed to get row detail: $err'),
    );
  }

  Future<ViewPB?> _createRowDocumentView(String viewId) async {
    final result = await ViewBackendService.createOrphanView(
      viewId: viewId,
      name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
      desc: '',
      layoutType: ViewLayoutPB.Document,
    );
    return result.fold(
      (view) => view,
      (error) {
        Log.error(error);
        return null;
      },
    );
  }
}

@freezed
class RowDocumentEvent with _$RowDocumentEvent {
  const factory RowDocumentEvent.initial() = _InitialRow;
  const factory RowDocumentEvent.didReceiveRowDocument(ViewPB view) =
      _DidReceiveRowDocument;
  const factory RowDocumentEvent.didReceiveError(FlowyError error) =
      _DidReceiveError;
  const factory RowDocumentEvent.updateIsEmpty(bool isDocumentEmpty) =
      _UpdateIsEmpty;
}

@freezed
class RowDocumentState with _$RowDocumentState {
  const factory RowDocumentState({
    ViewPB? viewPB,
    required LoadingState loadingState,
  }) = _RowDocumentState;

  factory RowDocumentState.initial() => const RowDocumentState(
        loadingState: LoadingState.loading(),
      );
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.error(FlowyError error) = _Error;
  const factory LoadingState.finish() = _Finish;
}
