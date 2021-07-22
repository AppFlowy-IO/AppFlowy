///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class EditorErrorCode extends $pb.ProtobufEnum {
  static const EditorErrorCode Unknown = EditorErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const EditorErrorCode EditorDBInternalError = EditorErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EditorDBInternalError');
  static const EditorErrorCode DocNameInvalid = EditorErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocNameInvalid');
  static const EditorErrorCode DocViewIdInvalid = EditorErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocViewIdInvalid');

  static const $core.List<EditorErrorCode> values = <EditorErrorCode> [
    Unknown,
    EditorDBInternalError,
    DocNameInvalid,
    DocViewIdInvalid,
  ];

  static final $core.Map<$core.int, EditorErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EditorErrorCode? valueOf($core.int value) => _byValue[value];

  const EditorErrorCode._($core.int v, $core.String n) : super(v, n);
}

