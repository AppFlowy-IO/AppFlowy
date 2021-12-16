///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'errors.pbenum.dart';

export 'errors.pbenum.dart';

class WSError extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WSError', createEmptyInstance: create)
    ..e<ErrorCode>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.OE, defaultOrMaker: ErrorCode.InternalError, valueOf: ErrorCode.valueOf, enumValues: ErrorCode.values)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'msg')
    ..hasRequiredFields = false
  ;

  WSError._() : super();
  factory WSError({
    ErrorCode? code,
    $core.String? msg,
  }) {
    final _result = create();
    if (code != null) {
      _result.code = code;
    }
    if (msg != null) {
      _result.msg = msg;
    }
    return _result;
  }
  factory WSError.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WSError.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WSError clone() => WSError()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WSError copyWith(void Function(WSError) updates) => super.copyWith((message) => updates(message as WSError)) as WSError; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WSError create() => WSError._();
  WSError createEmptyInstance() => create();
  static $pb.PbList<WSError> createRepeated() => $pb.PbList<WSError>();
  @$core.pragma('dart2js:noInline')
  static WSError getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WSError>(create);
  static WSError? _defaultInstance;

  @$pb.TagNumber(1)
  ErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ErrorCode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get msg => $_getSZ(1);
  @$pb.TagNumber(2)
  set msg($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearMsg() => clearField(2);
}

