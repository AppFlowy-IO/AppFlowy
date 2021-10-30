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
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appIds')
    ..hasRequiredFields = false
  ;

  QueryAppRequest._() : super();
  factory QueryAppRequest({
    $core.Iterable<$core.String>? appIds,
  }) {
    final _result = create();
    if (appIds != null) {
      _result.appIds.addAll(appIds);
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
  $core.List<$core.String> get appIds => $_getList(0);
}

class AppIdentifier extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppIdentifier', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..hasRequiredFields = false
  ;

  AppIdentifier._() : super();
  factory AppIdentifier({
    $core.String? appId,
  }) {
    final _result = create();
    if (appId != null) {
      _result.appId = appId;
    }
    return _result;
  }
  factory AppIdentifier.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppIdentifier.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppIdentifier clone() => AppIdentifier()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppIdentifier copyWith(void Function(AppIdentifier) updates) => super.copyWith((message) => updates(message as AppIdentifier)) as AppIdentifier; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppIdentifier create() => AppIdentifier._();
  AppIdentifier createEmptyInstance() => create();
  static $pb.PbList<AppIdentifier> createRepeated() => $pb.PbList<AppIdentifier>();
  @$core.pragma('dart2js:noInline')
  static AppIdentifier getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppIdentifier>(create);
  static AppIdentifier? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => clearField(1);
}

