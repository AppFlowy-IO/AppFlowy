///
//  Generated code. Do not modify.
//  source: trash.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TrashType extends $pb.ProtobufEnum {
  static const TrashType Unknown = TrashType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const TrashType TrashView = TrashType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TrashView');
  static const TrashType TrashApp = TrashType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TrashApp');

  static const $core.List<TrashType> values = <TrashType> [
    Unknown,
    TrashView,
    TrashApp,
  ];

  static final $core.Map<$core.int, TrashType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TrashType? valueOf($core.int value) => _byValue[value];

  const TrashType._($core.int v, $core.String n) : super(v, n);
}

