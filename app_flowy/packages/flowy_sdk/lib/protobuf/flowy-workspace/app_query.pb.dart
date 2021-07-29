///
//  Generated code. Do not modify.
//  source: app_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class QueryAppRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryAppRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'readViews')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  QueryAppRequest._() : super();
  factory QueryAppRequest({
    $core.String? appId,
    $core.bool? readViews,
    $core.bool? isTrash,
  }) {
    final _result = create();
    if (appId != null) {
      _result.appId = appId;
    }
    if (readViews != null) {
      _result.readViews = readViews;
    }
    if (isTrash != null) {
      _result.isTrash = isTrash;
    }
    return _result;
  }
  factory QueryAppRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryAppRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryAppRequest clone() => QueryAppRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryAppRequest copyWith(void Function(QueryAppRequest) updates) => super.copyWith((message) => updates(message as QueryAppRequest)) as QueryAppRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryAppRequest create() => QueryAppRequest._();
  QueryAppRequest createEmptyInstance() => create();
  static $pb.PbList<QueryAppRequest> createRepeated() => $pb.PbList<QueryAppRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryAppRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryAppRequest>(create);
  static QueryAppRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get readViews => $_getBF(1);
  @$pb.TagNumber(2)
  set readViews($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReadViews() => $_has(1);
  @$pb.TagNumber(2)
  void clearReadViews() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isTrash => $_getBF(2);
  @$pb.TagNumber(3)
  set isTrash($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIsTrash() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsTrash() => clearField(3);
}

