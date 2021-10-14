///
//  Generated code. Do not modify.
//  source: subject.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum SubscribeObject_OneOfPayload {
  payload, 
  notSet
}

enum SubscribeObject_OneOfError {
  error, 
  notSet
}

class SubscribeObject extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SubscribeObject_OneOfPayload> _SubscribeObject_OneOfPayloadByTag = {
    4 : SubscribeObject_OneOfPayload.payload,
    0 : SubscribeObject_OneOfPayload.notSet
  };
  static const $core.Map<$core.int, SubscribeObject_OneOfError> _SubscribeObject_OneOfErrorByTag = {
    5 : SubscribeObject_OneOfError.error,
    0 : SubscribeObject_OneOfError.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SubscribeObject', createEmptyInstance: create)
    ..oo(0, [4])
    ..oo(1, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'source')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.O3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'payload', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'error', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  SubscribeObject._() : super();
  factory SubscribeObject({
    $core.String? source,
    $core.int? ty,
    $core.String? id,
    $core.List<$core.int>? payload,
    $core.List<$core.int>? error,
  }) {
    final _result = create();
    if (source != null) {
      _result.source = source;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (id != null) {
      _result.id = id;
    }
    if (payload != null) {
      _result.payload = payload;
    }
    if (error != null) {
      _result.error = error;
    }
    return _result;
  }
  factory SubscribeObject.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SubscribeObject.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SubscribeObject clone() => SubscribeObject()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SubscribeObject copyWith(void Function(SubscribeObject) updates) => super.copyWith((message) => updates(message as SubscribeObject)) as SubscribeObject; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubscribeObject create() => SubscribeObject._();
  SubscribeObject createEmptyInstance() => create();
  static $pb.PbList<SubscribeObject> createRepeated() => $pb.PbList<SubscribeObject>();
  @$core.pragma('dart2js:noInline')
  static SubscribeObject getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscribeObject>(create);
  static SubscribeObject? _defaultInstance;

  SubscribeObject_OneOfPayload whichOneOfPayload() => _SubscribeObject_OneOfPayloadByTag[$_whichOneof(0)]!;
  void clearOneOfPayload() => clearField($_whichOneof(0));

  SubscribeObject_OneOfError whichOneOfError() => _SubscribeObject_OneOfErrorByTag[$_whichOneof(1)]!;
  void clearOneOfError() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get source => $_getSZ(0);
  @$pb.TagNumber(1)
  set source($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get ty => $_getIZ(1);
  @$pb.TagNumber(2)
  set ty($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTy() => $_has(1);
  @$pb.TagNumber(2)
  void clearTy() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get payload => $_getN(3);
  @$pb.TagNumber(4)
  set payload($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPayload() => $_has(3);
  @$pb.TagNumber(4)
  void clearPayload() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get error => $_getN(4);
  @$pb.TagNumber(5)
  set error($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => clearField(5);
}

