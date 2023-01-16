///
//  Generated code. Do not modify.
//  source: dart_notification.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GridDartNotification extends $pb.ProtobufEnum {
  static const GridDartNotification Unknown = GridDartNotification._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const GridDartNotification DidCreateBlock = GridDartNotification._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidCreateBlock');
  static const GridDartNotification DidUpdateGridViewRows = GridDartNotification._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateGridViewRows');
  static const GridDartNotification DidUpdateGridViewRowsVisibility = GridDartNotification._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateGridViewRowsVisibility');
  static const GridDartNotification DidUpdateGridFields = GridDartNotification._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateGridFields');
  static const GridDartNotification DidUpdateRow = GridDartNotification._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateRow');
  static const GridDartNotification DidUpdateCell = GridDartNotification._(40, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateCell');
  static const GridDartNotification DidUpdateField = GridDartNotification._(50, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateField');
  static const GridDartNotification DidUpdateGroupView = GridDartNotification._(60, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateGroupView');
  static const GridDartNotification DidUpdateGroup = GridDartNotification._(61, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateGroup');
  static const GridDartNotification DidGroupByNewField = GridDartNotification._(62, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidGroupByNewField');
  static const GridDartNotification DidUpdateFilter = GridDartNotification._(63, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateFilter');
  static const GridDartNotification DidUpdateSort = GridDartNotification._(64, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateSort');
  static const GridDartNotification DidReorderRows = GridDartNotification._(65, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidReorderRows');
  static const GridDartNotification DidReorderSingleRow = GridDartNotification._(66, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidReorderSingleRow');
  static const GridDartNotification DidUpdateGridSetting = GridDartNotification._(70, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DidUpdateGridSetting');

  static const $core.List<GridDartNotification> values = <GridDartNotification> [
    Unknown,
    DidCreateBlock,
    DidUpdateGridViewRows,
    DidUpdateGridViewRowsVisibility,
    DidUpdateGridFields,
    DidUpdateRow,
    DidUpdateCell,
    DidUpdateField,
    DidUpdateGroupView,
    DidUpdateGroup,
    DidGroupByNewField,
    DidUpdateFilter,
    DidUpdateSort,
    DidReorderRows,
    DidReorderSingleRow,
    DidUpdateGridSetting,
  ];

  static final $core.Map<$core.int, GridDartNotification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridDartNotification? valueOf($core.int value) => _byValue[value];

  const GridDartNotification._($core.int v, $core.String n) : super(v, n);
}

