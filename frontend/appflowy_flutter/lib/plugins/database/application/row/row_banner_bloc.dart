import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/row_meta_listener.dart';

part 'row_banner_bloc.freezed.dart';

class RowBannerBloc extends Bloc<RowBannerEvent, RowBannerState> {
  RowBannerBloc({
    required this.viewId,
    required this.fieldController,
    required RowMetaPB rowMeta,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _metaListener = RowMetaListener(rowMeta.id),
        super(RowBannerState.initial(rowMeta)) {
    _dispatch();
  }

  final String viewId;
  final FieldController fieldController;
  final RowBackendService _rowBackendSvc;
  final RowMetaListener _metaListener;

  @override
  Future<void> close() async {
    await _metaListener.stop();
    return super.close();
  }

  void _dispatch() {
    on<RowBannerEvent>(
      (event, emit) {
        event.when(
          initial: () {
            _loadPrimaryField();
            _listenRowMetaChanged();
          },
          didReceiveRowMeta: (RowMetaPB rowMeta) {
            emit(state.copyWith(rowMeta: rowMeta));
          },
          setCover: (String coverURL) => _updateMeta(coverURL: coverURL),
          setIcon: (String iconURL) => _updateMeta(iconURL: iconURL),
          didReceiveFieldUpdate: (updatedField) {
            emit(
              state.copyWith(
                primaryField: updatedField,
                loadingState: const LoadingState.finish(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadPrimaryField() async {
    final fieldOrError =
        await FieldBackendService.getPrimaryField(viewId: viewId);
    fieldOrError.fold(
      (primaryField) {
        if (!isClosed) {
          fieldController.addSingleFieldListener(
            primaryField.id,
            onFieldChanged: (updatedField) {
              if (!isClosed) {
                add(RowBannerEvent.didReceiveFieldUpdate(updatedField.field));
              }
            },
          );
          add(RowBannerEvent.didReceiveFieldUpdate(primaryField));
        }
      },
      (r) => Log.error(r),
    );
  }

  /// Listen the changes of the row meta and then update the banner
  void _listenRowMetaChanged() {
    _metaListener.start(
      callback: (rowMeta) {
        if (!isClosed) {
          add(RowBannerEvent.didReceiveRowMeta(rowMeta));
        }
      },
    );
  }

  /// Update the meta of the row and the view
  Future<void> _updateMeta({String? iconURL, String? coverURL}) async {
    final result = await _rowBackendSvc.updateMeta(
      iconURL: iconURL,
      coverURL: coverURL,
      rowId: state.rowMeta.id,
    );
    result.fold((l) => null, (err) => Log.error(err));
  }
}

@freezed
class RowBannerEvent with _$RowBannerEvent {
  const factory RowBannerEvent.initial() = _Initial;
  const factory RowBannerEvent.didReceiveRowMeta(RowMetaPB rowMeta) =
      _DidReceiveRowMeta;
  const factory RowBannerEvent.didReceiveFieldUpdate(FieldPB field) =
      _DidReceiveFieldUpdate;
  const factory RowBannerEvent.setIcon(String iconURL) = _SetIcon;
  const factory RowBannerEvent.setCover(String coverURL) = _SetCover;
}

@freezed
class RowBannerState with _$RowBannerState {
  const factory RowBannerState({
    required FieldPB? primaryField,
    required RowMetaPB rowMeta,
    required LoadingState loadingState,
  }) = _RowBannerState;

  factory RowBannerState.initial(RowMetaPB rowMetaPB) => RowBannerState(
        primaryField: null,
        rowMeta: rowMetaPB,
        loadingState: const LoadingState.loading(),
      );
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish() = _Finish;
}
