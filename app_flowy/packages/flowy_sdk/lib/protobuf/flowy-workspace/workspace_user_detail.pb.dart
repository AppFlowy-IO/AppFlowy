///
//  Generated code. Do not modify.
//  source: workspace_user_detail.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'workspace_create.pb.dart' as $0;

class UserWorkspace extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserWorkspace', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'owner')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..hasRequiredFields = false
  ;

  UserWorkspace._() : super();
  factory UserWorkspace({
    $core.String? owner,
    $core.String? workspaceId,
  }) {
    final _result = create();
    if (owner != null) {
      _result.owner = owner;
    }
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    return _result;
  }
  factory UserWorkspace.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserWorkspace.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserWorkspace clone() => UserWorkspace()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserWorkspace copyWith(void Function(UserWorkspace) updates) => super.copyWith((message) => updates(message as UserWorkspace)) as UserWorkspace; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserWorkspace create() => UserWorkspace._();
  UserWorkspace createEmptyInstance() => create();
  static $pb.PbList<UserWorkspace> createRepeated() => $pb.PbList<UserWorkspace>();
  @$core.pragma('dart2js:noInline')
  static UserWorkspace getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserWorkspace>(create);
  static UserWorkspace? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get owner => $_getSZ(0);
  @$pb.TagNumber(1)
  set owner($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOwner() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwner() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => clearField(2);
}

class UserWorkspaceDetail extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserWorkspaceDetail', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'owner')
    ..aOM<$0.Workspace>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspace', subBuilder: $0.Workspace.create)
    ..hasRequiredFields = false
  ;

  UserWorkspaceDetail._() : super();
  factory UserWorkspaceDetail({
    $core.String? owner,
    $0.Workspace? workspace,
  }) {
    final _result = create();
    if (owner != null) {
      _result.owner = owner;
    }
    if (workspace != null) {
      _result.workspace = workspace;
    }
    return _result;
  }
  factory UserWorkspaceDetail.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserWorkspaceDetail.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserWorkspaceDetail clone() => UserWorkspaceDetail()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserWorkspaceDetail copyWith(void Function(UserWorkspaceDetail) updates) => super.copyWith((message) => updates(message as UserWorkspaceDetail)) as UserWorkspaceDetail; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserWorkspaceDetail create() => UserWorkspaceDetail._();
  UserWorkspaceDetail createEmptyInstance() => create();
  static $pb.PbList<UserWorkspaceDetail> createRepeated() => $pb.PbList<UserWorkspaceDetail>();
  @$core.pragma('dart2js:noInline')
  static UserWorkspaceDetail getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserWorkspaceDetail>(create);
  static UserWorkspaceDetail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get owner => $_getSZ(0);
  @$pb.TagNumber(1)
  set owner($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOwner() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwner() => clearField(1);

  @$pb.TagNumber(2)
  $0.Workspace get workspace => $_getN(1);
  @$pb.TagNumber(2)
  set workspace($0.Workspace v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkspace() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspace() => clearField(2);
  @$pb.TagNumber(2)
  $0.Workspace ensureWorkspace() => $_ensure(1);
}

