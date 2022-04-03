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
  static const GridNotification DidCreateBlock = GridNotification._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidCreateBlock');
  static const GridNotification DidUpdateRow = GridNotification._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateRow');
  static const GridNotification GridDidUpdateCells = GridNotification._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridDidUpdateCells');
  static const GridNotification DidUpdateFields = GridNotification._(40, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateFields');
  static const GridNotification DidUpdateField = GridNotification._(41, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateField');

  static const $core.List<GridNotification> values = <GridNotification> [
    Unknown,
    DidCreateBlock,
    DidUpdateRow,
    GridDidUpdateCells,
    DidUpdateFields,
    DidUpdateField,
  ];

  static final $core.Map<$core.int, GridNotification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridNotification? valueOf($core.int value) => _byValue[value];

  const GridNotification._($core.int v, $core.String n) : super(v, n);
}

