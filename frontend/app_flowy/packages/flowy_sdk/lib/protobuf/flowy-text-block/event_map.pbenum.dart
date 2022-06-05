///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TextBlockEvent extends $pb.ProtobufEnum {
  static const TextBlockEvent GetBlockData = TextBlockEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetBlockData');
  static const TextBlockEvent ApplyDelta = TextBlockEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ApplyDelta');
  static const TextBlockEvent ExportDocument = TextBlockEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ExportDocument');

  static const $core.List<TextBlockEvent> values = <TextBlockEvent> [
    GetBlockData,
    ApplyDelta,
    ExportDocument,
  ];

  static final $core.Map<$core.int, TextBlockEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TextBlockEvent? valueOf($core.int value) => _byValue[value];

  const TextBlockEvent._($core.int v, $core.String n) : super(v, n);
}

