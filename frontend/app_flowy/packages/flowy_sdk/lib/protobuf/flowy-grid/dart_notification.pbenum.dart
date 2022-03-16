///
//  Generated code. Do not modify.
//  source: dart_notification.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GridNotification extends $pb.ProtobufEnum {
  static const GridNotification Unknown = GridNotification._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const GridNotification GridDidCreateRows = GridNotification._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridDidCreateRows');
  static const GridNotification GridDidDeleteRow = GridNotification._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridDidDeleteRow');
  static const GridNotification GridDidUpdateRows = GridNotification._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridDidUpdateRows');
  static const GridNotification GridDidUpdateCells = GridNotification._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridDidUpdateCells');
  static const GridNotification GridDidUpdateFields = GridNotification._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridDidUpdateFields');

  static const $core.List<GridNotification> values = <GridNotification> [
    Unknown,
    GridDidCreateRows,
    GridDidDeleteRow,
    GridDidUpdateRows,
    GridDidUpdateCells,
    GridDidUpdateFields,
  ];

  static final $core.Map<$core.int, GridNotification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridNotification? valueOf($core.int value) => _byValue[value];

  const GridNotification._($core.int v, $core.String n) : super(v, n);
}

