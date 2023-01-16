///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DocumentEvent extends $pb.ProtobufEnum {
  static const DocumentEvent GetDocument = DocumentEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetDocument');
  static const DocumentEvent ApplyEdit = DocumentEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ApplyEdit');
  static const DocumentEvent ExportDocument = DocumentEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ExportDocument');

  static const $core.List<DocumentEvent> values = <DocumentEvent> [
    GetDocument,
    ApplyEdit,
    ExportDocument,
  ];

  static final $core.Map<$core.int, DocumentEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DocumentEvent? valueOf($core.int value) => _byValue[value];

  const DocumentEvent._($core.int v, $core.String n) : super(v, n);
}

