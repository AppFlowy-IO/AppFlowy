import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

import '../grid/presentation/widgets/filter/filter_info.dart';
import 'field/field_controller.dart';
import 'row/row_cache.dart';
import 'row/row_service.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);

typedef OnRowsCreated = void Function(List<RowId> ids);
typedef OnRowsUpdated = void Function(List<RowId> ids);
typedef OnRowsDeleted = void Function(List<RowId> ids);
typedef OnNumOfRowsChanged = void Function(
  UnmodifiableListView<RowInfo> rows,
  UnmodifiableMapView<RowId, RowInfo> rowByRowId,
  RowsChangedReason reason,
);

typedef OnError = void Function(FlowyError);
