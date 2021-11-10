///
//  Generated code. Do not modify.
//  source: export.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ExportType extends $pb.ProtobufEnum {
  static const ExportType Text = ExportType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Text');
  static const ExportType Markdown = ExportType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Markdown');
  static const ExportType Link = ExportType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Link');

  static const $core.List<ExportType> values = <ExportType> [
    Text,
    Markdown,
    Link,
  ];

  static final $core.Map<$core.int, ExportType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ExportType? valueOf($core.int value) => _byValue[value];

  const ExportType._($core.int v, $core.String n) : super(v, n);
}

