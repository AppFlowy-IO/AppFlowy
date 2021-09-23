///
//  Generated code. Do not modify.
//  source: msg.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WsSource extends $pb.ProtobufEnum {
  static const WsSource Doc = WsSource._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Doc');

  static const $core.List<WsSource> values = <WsSource> [
    Doc,
  ];

  static final $core.Map<$core.int, WsSource> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WsSource? valueOf($core.int value) => _byValue[value];

  const WsSource._($core.int v, $core.String n) : super(v, n);
}

