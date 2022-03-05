///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class BlockEvent extends $pb.ProtobufEnum {
  static const BlockEvent ApplyDocDelta = BlockEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ApplyDocDelta');
  static const BlockEvent ExportDocument = BlockEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ExportDocument');

  static const $core.List<BlockEvent> values = <BlockEvent> [
    ApplyDocDelta,
    ExportDocument,
  ];

  static final $core.Map<$core.int, BlockEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static BlockEvent? valueOf($core.int value) => _byValue[value];

  const BlockEvent._($core.int v, $core.String n) : super(v, n);
}

