///
//  Generated code. Do not modify.
//  source: model.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class RevType extends $pb.ProtobufEnum {
  static const RevType Local = RevType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Local');
  static const RevType Remote = RevType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Remote');

  static const $core.List<RevType> values = <RevType> [
    Local,
    Remote,
  ];

  static final $core.Map<$core.int, RevType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RevType? valueOf($core.int value) => _byValue[value];

  const RevType._($core.int v, $core.String n) : super(v, n);
}

