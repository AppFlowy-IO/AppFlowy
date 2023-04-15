import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:fixnum/fixnum.dart';

import '../grid/presentation/widgets/filter/filter_info.dart';
import 'field/field_controller.dart';
import 'row/row_cache.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);

typedef OnRowsCreated = void Function(List<Int64> ids);
typedef OnRowsUpdated = void Function(List<Int64> ids);
typedef OnRowsDeleted = void Function(List<Int64> ids);
typedef OnRowsChanged = void Function(
  UnmodifiableListView<RowInfo> rows,
  UnmodifiableMapView<Int64, RowInfo> rowByRowId,
  RowsChangedReason reason,
);

typedef OnError = void Function(FlowyError);
