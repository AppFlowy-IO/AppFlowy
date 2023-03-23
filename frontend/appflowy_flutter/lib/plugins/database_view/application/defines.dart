import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

import '../grid/presentation/widgets/filter/filter_info.dart';
import 'field/field_controller.dart';
import 'row/row_cache.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);

typedef OnRowsCreated = void Function(List<String> ids);
typedef OnRowsUpdated = void Function(List<String> ids);
typedef OnRowsDeleted = void Function(List<String> ids);
typedef OnRowsChanged = void Function(
  UnmodifiableListView<RowInfo> rows,
  UnmodifiableMapView<String, RowInfo> rowByRowId,
  RowsChangedReason reason,
);

typedef OnError = void Function(FlowyError);
