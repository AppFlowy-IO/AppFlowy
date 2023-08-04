import 'package:appflowy/plugins/database_view/application/field/field_listener.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'row_meta_listener.dart';

part 'row_banner_bloc.freezed.dart';

class RowBannerBloc extends Bloc<RowBannerEvent, RowBannerState> {
  final String viewId;
  final RowBackendService _rowBackendSvc;
  final RowMetaListener _metaListener;
  SingleFieldListener? _fieldListener;

  RowBannerBloc({
    required this.viewId,
    required RowMetaPB rowMeta,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _metaListener = RowMetaListener(rowMeta.id),
        super(RowBannerState.initial(rowMeta)) {
    on<RowBannerEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _loadPrimaryField();
            await _listenRowMeteChanged();
          },
          didReceiveRowMeta: (RowMetaPB rowMeta) {
            emit(
              state.copyWith(
                rowMeta: rowMeta,
              ),
            );
          },
          setCover: (String coverURL) {
            _updateMeta(coverURL: coverURL);
          },
          setIcon: (String iconURL) {
            _updateMeta(iconURL: iconURL);
          },
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

  @override
  Future<void> close() async {
    await _metaListener.stop();
    await _fieldListener?.stop();
    _fieldListener = null;

    return super.close();
  }

  Future<void> _loadPrimaryField() async {
    final fieldOrError =
        await FieldBackendService.getPrimaryField(viewId: viewId);
    fieldOrError.fold(
      (primaryField) {
        if (!isClosed) {
          _fieldListener = SingleFieldListener(fieldId: primaryField.id);
          _fieldListener?.start(
            onFieldChanged: (updatedField) {
              if (!isClosed) {
                add(RowBannerEvent.didReceiveFieldUpdate(updatedField));
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
  Future<void> _listenRowMeteChanged() async {
    _metaListener.start(
      callback: (rowMeta) {
        add(RowBannerEvent.didReceiveRowMeta(rowMeta));
      },
    );
  }

  /// Update the meta of the row and the view
  Future<void> _updateMeta({
    String? iconURL,
    String? coverURL,
  }) async {
    // Most of the time, the result is success, so we don't need to handle it.
    await _rowBackendSvc
        .updateMeta(
      iconURL: iconURL,
      coverURL: coverURL,
      rowId: state.rowMeta.id,
    )
        .then((result) {
      result.fold(
        (l) => null,
        (err) => Log.error(err),
      );
    });
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
    ViewPB? view,
    FieldPB? primaryField,
    required RowMetaPB rowMeta,
    required LoadingState loadingState,
  }) = _RowBannerState;

  factory RowBannerState.initial(RowMetaPB rowMetaPB) => RowBannerState(
        rowMeta: rowMetaPB,
        loadingState: const LoadingState.loading(),
      );
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish() = _Finish;
}
