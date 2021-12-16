///
//  Generated code. Do not modify.
//  source: ws.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DocumentWSDataType extends $pb.ProtobufEnum {
  static const DocumentWSDataType Acked = DocumentWSDataType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Acked');
  static const DocumentWSDataType PushRev = DocumentWSDataType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PushRev');
  static const DocumentWSDataType PullRev = DocumentWSDataType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PullRev');
  static const DocumentWSDataType UserConnect = DocumentWSDataType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserConnect');

  static const $core.List<DocumentWSDataType> values = <DocumentWSDataType> [
    Acked,
    PushRev,
    PullRev,
    UserConnect,
  ];

  static final $core.Map<$core.int, DocumentWSDataType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DocumentWSDataType? valueOf($core.int value) => _byValue[value];

  const DocumentWSDataType._($core.int v, $core.String n) : super(v, n);
}

