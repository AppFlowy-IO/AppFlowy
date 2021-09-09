///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class EditorEvent extends $pb.ProtobufEnum {
  static const EditorEvent CreateDoc = EditorEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateDoc');
  static const EditorEvent UpdateDoc = EditorEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateDoc');
  static const EditorEvent ReadDoc = EditorEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadDoc');
  static const EditorEvent DeleteDoc = EditorEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteDoc');

  static const $core.List<EditorEvent> values = <EditorEvent> [
    CreateDoc,
    UpdateDoc,
    ReadDoc,
    DeleteDoc,
  ];

  static final $core.Map<$core.int, EditorEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EditorEvent? valueOf($core.int value) => _byValue[value];

  const EditorEvent._($core.int v, $core.String n) : super(v, n);
}

