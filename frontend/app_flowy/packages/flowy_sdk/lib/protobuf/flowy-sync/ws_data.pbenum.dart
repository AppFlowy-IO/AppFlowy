///
//  Generated code. Do not modify.
//  source: ws_data.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ClientRevisionWSDataType extends $pb.ProtobufEnum {
  static const ClientRevisionWSDataType ClientPushRev = ClientRevisionWSDataType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ClientPushRev');
  static const ClientRevisionWSDataType ClientPing = ClientRevisionWSDataType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ClientPing');

  static const $core.List<ClientRevisionWSDataType> values = <ClientRevisionWSDataType> [
    ClientPushRev,
    ClientPing,
  ];

  static final $core.Map<$core.int, ClientRevisionWSDataType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ClientRevisionWSDataType? valueOf($core.int value) => _byValue[value];

  const ClientRevisionWSDataType._($core.int v, $core.String n) : super(v, n);
}

class ServerRevisionWSDataType extends $pb.ProtobufEnum {
  static const ServerRevisionWSDataType ServerAck = ServerRevisionWSDataType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ServerAck');
  static const ServerRevisionWSDataType ServerPushRev = ServerRevisionWSDataType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ServerPushRev');
  static const ServerRevisionWSDataType ServerPullRev = ServerRevisionWSDataType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ServerPullRev');
  static const ServerRevisionWSDataType UserConnect = ServerRevisionWSDataType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserConnect');

  static const $core.List<ServerRevisionWSDataType> values = <ServerRevisionWSDataType> [
    ServerAck,
    ServerPushRev,
    ServerPullRev,
    UserConnect,
  ];

  static final $core.Map<$core.int, ServerRevisionWSDataType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ServerRevisionWSDataType? valueOf($core.int value) => _byValue[value];

  const ServerRevisionWSDataType._($core.int v, $core.String n) : super(v, n);
}

