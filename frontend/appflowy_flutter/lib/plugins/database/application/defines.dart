import 'dart:collection';

// TODO(RS): remove dependency on presentation code
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'field/field_info.dart';
import 'row/row_cache.dart';
import 'row/row_service.dart';

part 'defines.freezed.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnSortsChanged = void Function(List<SortInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);

typedef OnRowsCreated = void Function(List<RowId> rowIds);
typedef OnRowsUpdated = void Function(
  List<RowId> rowIds,
  ChangedReason reason,
);
typedef OnRowsDeleted = void Function(List<RowId> rowIds);
typedef OnNumOfRowsChanged = void Function(
  UnmodifiableListView<RowInfo> rows,
  UnmodifiableMapView<RowId, RowInfo> rowById,
  ChangedReason reason,
);

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.idle() = _Idle;
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish(
    FlowyResult<void, FlowyError> successOrFail,
  ) = _Finish;

  const LoadingState._();
  bool isLoading() => this is _Loading;
}
