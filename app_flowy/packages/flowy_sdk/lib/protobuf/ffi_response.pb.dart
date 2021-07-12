///
//  Generated code. Do not modify.
//  source: ffi_response.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'ffi_response.pbenum.dart';

export 'ffi_response.pbenum.dart';

class FFIResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FFIResponse', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'payload', $pb.PbFieldType.OY)
    ..e<FFIStatusCode>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.OE, defaultOrMaker: FFIStatusCode.Unknown, valueOf: FFIStatusCode.valueOf, enumValues: FFIStatusCode.values)
    ..hasRequiredFields = false
  ;

  FFIResponse._() : super();
  factory FFIResponse({
    $core.List<$core.int>? payload,
    FFIStatusCode? code,
  }) {
    final _result = create();
    if (payload != null) {
      _result.payload = payload;
    }
    if (code != null) {
      _result.code = code;
    }
    return _result;
  }
  factory FFIResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FFIResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FFIResponse clone() => FFIResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FFIResponse copyWith(void Function(FFIResponse) updates) => super.copyWith((message) => updates(message as FFIResponse)) as FFIResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FFIResponse create() => FFIResponse._();
  FFIResponse createEmptyInstance() => create();
  static $pb.PbList<FFIResponse> createRepeated() => $pb.PbList<FFIResponse>();
  @$core.pragma('dart2js:noInline')
  static FFIResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FFIResponse>(create);
  static FFIResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get payload => $_getN(0);
  @$pb.TagNumber(1)
  set payload($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayload() => clearField(1);

  @$pb.TagNumber(2)
  FFIStatusCode get code => $_getN(1);
  @$pb.TagNumber(2)
  set code(FFIStatusCode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => clearField(2);
}

