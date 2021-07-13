///
//  Generated code. Do not modify.
//  source: ffi_response.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FFIStatusCode extends $pb.ProtobufEnum {
  static const FFIStatusCode Unknown = FFIStatusCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const FFIStatusCode Ok = FFIStatusCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Ok');
  static const FFIStatusCode Err = FFIStatusCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Err');

  static const $core.List<FFIStatusCode> values = <FFIStatusCode> [
    Unknown,
    Ok,
    Err,
  ];

  static final $core.Map<$core.int, FFIStatusCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FFIStatusCode? valueOf($core.int value) => _byValue[value];

  const FFIStatusCode._($core.int v, $core.String n) : super(v, n);
}

