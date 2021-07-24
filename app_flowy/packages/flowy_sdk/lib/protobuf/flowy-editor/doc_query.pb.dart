///
//  Generated code. Do not modify.
//  source: doc_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class QueryDocRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryDocRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..hasRequiredFields = false
  ;

  QueryDocRequest._() : super();
  factory QueryDocRequest({
    $core.String? docId,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    return _result;
  }
  factory QueryDocRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryDocRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryDocRequest clone() => QueryDocRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryDocRequest copyWith(void Function(QueryDocRequest) updates) => super.copyWith((message) => updates(message as QueryDocRequest)) as QueryDocRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryDocRequest create() => QueryDocRequest._();
  QueryDocRequest createEmptyInstance() => create();
  static $pb.PbList<QueryDocRequest> createRepeated() => $pb.PbList<QueryDocRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryDocRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryDocRequest>(create);
  static QueryDocRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);
}

class QueryDocDataRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryDocDataRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..hasRequiredFields = false
  ;

  QueryDocDataRequest._() : super();
  factory QueryDocDataRequest({
    $core.String? docId,
    $core.String? path,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (path != null) {
      _result.path = path;
    }
    return _result;
  }
  factory QueryDocDataRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryDocDataRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryDocDataRequest clone() => QueryDocDataRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryDocDataRequest copyWith(void Function(QueryDocDataRequest) updates) => super.copyWith((message) => updates(message as QueryDocDataRequest)) as QueryDocDataRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryDocDataRequest create() => QueryDocDataRequest._();
  QueryDocDataRequest createEmptyInstance() => create();
  static $pb.PbList<QueryDocDataRequest> createRepeated() => $pb.PbList<QueryDocDataRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryDocDataRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryDocDataRequest>(create);
  static QueryDocDataRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);
}

