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
  static const EditorErrorCode EditorDBConnFailed = EditorErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EditorDBConnFailed');
  static const EditorErrorCode DocNameInvalid = EditorErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocNameInvalid');
  static const EditorErrorCode DocViewIdInvalid = EditorErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocViewIdInvalid');
  static const EditorErrorCode DocDescTooLong = EditorErrorCode._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocDescTooLong');
  static const EditorErrorCode DocOpenFileError = EditorErrorCode._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocOpenFileError');
  static const EditorErrorCode DocFilePathInvalid = EditorErrorCode._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocFilePathInvalid');
  static const EditorErrorCode EditorUserNotLoginYet = EditorErrorCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EditorUserNotLoginYet');

  static const $core.List<EditorErrorCode> values = <EditorErrorCode> [
    Unknown,
    EditorDBInternalError,
    EditorDBConnFailed,
    DocNameInvalid,
    DocViewIdInvalid,
    DocDescTooLong,
    DocOpenFileError,
    DocFilePathInvalid,
    EditorUserNotLoginYet,
  ];

  static final $core.Map<$core.int, EditorErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EditorErrorCode? valueOf($core.int value) => _byValue[value];

  const EditorErrorCode._($core.int v, $core.String n) : super(v, n);
}

