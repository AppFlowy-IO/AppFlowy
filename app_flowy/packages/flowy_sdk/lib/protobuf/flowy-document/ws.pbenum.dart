///
//  Generated code. Do not modify.
//  source: ws.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WsDataType extends $pb.ProtobufEnum {
  static const WsDataType Acked = WsDataType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Acked');
  static const WsDataType PushRev = WsDataType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PushRev');
  static const WsDataType PullRev = WsDataType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PullRev');
  static const WsDataType Conflict = WsDataType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Conflict');
  static const WsDataType NewDocUser = WsDataType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NewDocUser');

  static const $core.List<WsDataType> values = <WsDataType> [
    Acked,
    PushRev,
    PullRev,
    Conflict,
    NewDocUser,
  ];

  static final $core.Map<$core.int, WsDataType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WsDataType? valueOf($core.int value) => _byValue[value];

  const WsDataType._($core.int v, $core.String n) : super(v, n);
}

