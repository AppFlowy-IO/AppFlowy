import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-database/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

import '../grid/presentation/widgets/filter/filter_info.dart';
import 'field/field_controller.dart';
import 'row/row_cache.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);
typedef OnRowsChanged = void Function(
  List<RowInfo>,
  RowsChangedReason,
);

typedef OnError = void Function(FlowyError);
