///
//  Generated code. Do not modify.
//  source: workspace_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class QueryWorkspaceRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryWorkspaceRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'readApps')
    ..hasRequiredFields = false
  ;

  QueryWorkspaceRequest._() : super();
  factory QueryWorkspaceRequest({
    $core.String? workspaceId,
    $core.bool? readApps,
  }) {
    final _result = create();
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    if (readApps != null) {
      _result.readApps = readApps;
    }
    return _result;
  }
  factory QueryWorkspaceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryWorkspaceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryWorkspaceRequest clone() => QueryWorkspaceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryWorkspaceRequest copyWith(void Function(QueryWorkspaceRequest) updates) => super.copyWith((message) => updates(message as QueryWorkspaceRequest)) as QueryWorkspaceRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryWorkspaceRequest create() => QueryWorkspaceRequest._();
  QueryWorkspaceRequest createEmptyInstance() => create();
  static $pb.PbList<QueryWorkspaceRequest> createRepeated() => $pb.PbList<QueryWorkspaceRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryWorkspaceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryWorkspaceRequest>(create);
  static QueryWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get readApps => $_getBF(1);
  @$pb.TagNumber(2)
  set readApps($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReadApps() => $_has(1);
  @$pb.TagNumber(2)
  void clearReadApps() => clearField(2);
}

