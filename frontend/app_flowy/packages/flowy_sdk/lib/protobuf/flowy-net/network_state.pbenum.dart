///
//  Generated code. Do not modify.
//  source: network_state.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class NetworkType extends $pb.ProtobufEnum {
  static const NetworkType UnknownNetworkType = NetworkType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UnknownNetworkType');
  static const NetworkType Wifi = NetworkType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Wifi');
  static const NetworkType Cell = NetworkType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Cell');
  static const NetworkType Ethernet = NetworkType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Ethernet');
  static const NetworkType Bluetooth = NetworkType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Bluetooth');
  static const NetworkType VPN = NetworkType._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VPN');

  static const $core.List<NetworkType> values = <NetworkType> [
    UnknownNetworkType,
    Wifi,
    Cell,
    Ethernet,
    Bluetooth,
    VPN,
  ];

  static final $core.Map<$core.int, NetworkType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NetworkType? valueOf($core.int value) => _byValue[value];

  const NetworkType._($core.int v, $core.String n) : super(v, n);
}

