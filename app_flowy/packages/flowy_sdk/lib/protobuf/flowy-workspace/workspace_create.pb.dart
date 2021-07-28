///
//  Generated code. Do not modify.
//  source: workspace_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'app_create.pb.dart' as $0;

class CreateWorkspaceRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateWorkspaceRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  CreateWorkspaceRequest._() : super();
  factory CreateWorkspaceRequest({
    $core.String? name,
    $core.String? desc,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    return _result;
  }
  factory CreateWorkspaceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateWorkspaceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateWorkspaceRequest clone() => CreateWorkspaceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateWorkspaceRequest copyWith(void Function(CreateWorkspaceRequest) updates) => super.copyWith((message) => updates(message as CreateWorkspaceRequest)) as CreateWorkspaceRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateWorkspaceRequest create() => CreateWorkspaceRequest._();
  CreateWorkspaceRequest createEmptyInstance() => create();
  static $pb.PbList<CreateWorkspaceRequest> createRepeated() => $pb.PbList<CreateWorkspaceRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateWorkspaceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateWorkspaceRequest>(create);
  static CreateWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get desc => $_getSZ(1);
  @$pb.TagNumber(2)
  set desc($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDesc() => $_has(1);
  @$pb.TagNumber(2)
  void clearDesc() => clearField(2);
}

class Workspace extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Workspace', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<$0.RepeatedApp>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'apps', subBuilder: $0.RepeatedApp.create)
    ..hasRequiredFields = false
  ;

  Workspace._() : super();
  factory Workspace({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    $0.RepeatedApp? apps,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (apps != null) {
      _result.apps = apps;
    }
    return _result;
  }
  factory Workspace.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Workspace.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Workspace clone() => Workspace()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Workspace copyWith(void Function(Workspace) updates) => super.copyWith((message) => updates(message as Workspace)) as Workspace; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Workspace create() => Workspace._();
  Workspace createEmptyInstance() => create();
  static $pb.PbList<Workspace> createRepeated() => $pb.PbList<Workspace>();
  @$core.pragma('dart2js:noInline')
  static Workspace getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Workspace>(create);
  static Workspace? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  $0.RepeatedApp get apps => $_getN(3);
  @$pb.TagNumber(4)
  set apps($0.RepeatedApp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasApps() => $_has(3);
  @$pb.TagNumber(4)
  void clearApps() => clearField(4);
  @$pb.TagNumber(4)
  $0.RepeatedApp ensureApps() => $_ensure(3);
}

class Workspaces extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Workspaces', createEmptyInstance: create)
    ..pc<Workspace>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: Workspace.create)
    ..hasRequiredFields = false
  ;

  Workspaces._() : super();
  factory Workspaces({
    $core.Iterable<Workspace>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory Workspaces.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Workspaces.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Workspaces clone() => Workspaces()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Workspaces copyWith(void Function(Workspaces) updates) => super.copyWith((message) => updates(message as Workspaces)) as Workspaces; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Workspaces create() => Workspaces._();
  Workspaces createEmptyInstance() => create();
  static $pb.PbList<Workspaces> createRepeated() => $pb.PbList<Workspaces>();
  @$core.pragma('dart2js:noInline')
  static Workspaces getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Workspaces>(create);
  static Workspaces? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Workspace> get items => $_getList(0);
}

