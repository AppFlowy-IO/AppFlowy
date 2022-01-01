///
//  Generated code. Do not modify.
//  source: revision.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class RevisionState extends $pb.ProtobufEnum {
  static const RevisionState StateLocal = RevisionState._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'StateLocal');
  static const RevisionState Ack = RevisionState._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Ack');

  static const $core.List<RevisionState> values = <RevisionState> [
    StateLocal,
    Ack,
  ];

  static final $core.Map<$core.int, RevisionState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RevisionState? valueOf($core.int value) => _byValue[value];

  const RevisionState._($core.int v, $core.String n) : super(v, n);
}

class RevType extends $pb.ProtobufEnum {
  static const RevType DeprecatedLocal = RevType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeprecatedLocal');
  static const RevType DeprecatedRemote = RevType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeprecatedRemote');

  static const $core.List<RevType> values = <RevType> [
    DeprecatedLocal,
    DeprecatedRemote,
  ];

  static final $core.Map<$core.int, RevType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RevType? valueOf($core.int value) => _byValue[value];

  const RevType._($core.int v, $core.String n) : super(v, n);
}

