import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

import '../../../application/row/row_service.dart';

part 'row_document_bloc.freezed.dart';

class RowDocumentBloc extends Bloc<RowDocumentEvent, RowDocumentState> {
  final String rowId;
  final RowBackendService _rowBackendSvc;

  RowDocumentBloc({
    required this.rowId,
    required String viewId,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        super(RowDocumentState.initial()) {
    on<RowDocumentEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _getRowDocumentView();
          },
          getRowDetail: () {},
          didReceiveRowDocument: (view) {
            emit(state.copyWith(viewPB: view));
          },
        );
      },
    );
  }

  Future<void> _getRowDocumentView() async {
    final rowDetailOrError = await _rowBackendSvc.getRowDetail(rowId);
    rowDetailOrError.fold(
      (rowDetail) async {
        final viewsOrError =
            await ViewBackendService.getView(rowDetail.documentId);
        viewsOrError.fold(
          (view) => add(RowDocumentEvent.didReceiveRowDocument(view)),
          (error) => Log.error(error),
        );
      },
      (err) {
        if (err.code == ErrorCode.RecordNotFound.value) {
          // By default, the document of the row is not exist. So creating a
          // new document for the given document id of the row.
        }
      },
    );
  }

  Future<void> _createRowDocumentView(String viewId) async {
    final result = await ViewBackendService.createView(
      parentViewId: viewId,
      name: '',
      desc: '',
      layoutType: ViewLayoutPB.Document,
    );
    result.fold(
      (view) {},
      (error) {
        Log.error(error);
      },
    );
  }
}

@freezed
class RowDocumentEvent with _$RowDocumentEvent {
  const factory RowDocumentEvent.initial() = _InitialRow;
  const factory RowDocumentEvent.didReceiveRowDocument(ViewPB view) =
      _DidReceiveRowDocument;
  const factory RowDocumentEvent.getRowDetail() = _GetRowDetail;
}

@freezed
class RowDocumentState with _$RowDocumentState {
  const factory RowDocumentState({
    RowDetailPB? rowDetailPB,
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
