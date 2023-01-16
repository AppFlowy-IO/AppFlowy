///
//  Generated code. Do not modify.
//  source: entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

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

class DocumentVersionPB extends $pb.ProtobufEnum {
  static const DocumentVersionPB V0 = DocumentVersionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'V0');
  static const DocumentVersionPB V1 = DocumentVersionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'V1');

  static const $core.List<DocumentVersionPB> values = <DocumentVersionPB> [
    V0,
    V1,
  ];

  static final $core.Map<$core.int, DocumentVersionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DocumentVersionPB? valueOf($core.int value) => _byValue[value];

  const DocumentVersionPB._($core.int v, $core.String n) : super(v, n);
}

