import 'dart:collection';

import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../grid/presentation/widgets/filter/filter_info.dart';
import 'field/field_info.dart';
import 'row/row_cache.dart';
import 'row/row_service.dart';

part 'defines.freezed.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnSortsChanged = void Function(List<SortInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);

typedef OnRowsCreated = void Function(List<RowId> ids);
typedef OnRowsUpdated = void Function(
  List<RowId> ids,
  ChangedReason reason,
);
typedef OnRowsDeleted = void Function(List<RowId> ids);
typedef OnNumOfRowsChanged = void Function(
  UnmodifiableListView<RowInfo> rows,
  UnmodifiableMapView<RowId, RowInfo> rowByRowId,
  ChangedReason reason,
);

typedef OnError = void Function(FlowyError);

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish(
    Either<Unit, FlowyError> successOrFail,
  ) = _Finish;

  const LoadingState._();
  isLoading() => this is _Loading;
}
