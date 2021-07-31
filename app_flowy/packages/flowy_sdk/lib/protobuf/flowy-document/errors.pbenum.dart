///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DocErrorCode extends $pb.ProtobufEnum {
  static const DocErrorCode Unknown = DocErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const DocErrorCode EditorDBInternalError = DocErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EditorDBInternalError');
  static const DocErrorCode EditorDBConnFailed = DocErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EditorDBConnFailed');
  static const DocErrorCode DocNameInvalid = DocErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocNameInvalid');
  static const DocErrorCode DocViewIdInvalid = DocErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocViewIdInvalid');
  static const DocErrorCode DocDescTooLong = DocErrorCode._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocDescTooLong');
  static const DocErrorCode DocOpenFileError = DocErrorCode._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocOpenFileError');
  static const DocErrorCode DocFilePathInvalid = DocErrorCode._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DocFilePathInvalid');
  static const DocErrorCode EditorUserNotLoginYet = DocErrorCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EditorUserNotLoginYet');

  static const $core.List<DocErrorCode> values = <DocErrorCode> [
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

  static final $core.Map<$core.int, DocErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DocErrorCode? valueOf($core.int value) => _byValue[value];

  const DocErrorCode._($core.int v, $core.String n) : super(v, n);
}

