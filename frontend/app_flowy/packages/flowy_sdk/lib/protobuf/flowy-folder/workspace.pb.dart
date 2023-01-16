///
//  Generated code. Do not modify.
//  source: workspace.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'app.pb.dart' as $0;
import 'view.pb.dart' as $1;

class WorkspacePB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WorkspacePB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<$0.RepeatedAppPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'apps', subBuilder: $0.RepeatedAppPB.create)
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..hasRequiredFields = false
  ;

  WorkspacePB._() : super();
  factory WorkspacePB({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    $0.RepeatedAppPB? apps,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
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
    if (modifiedTime != null) {
      _result.modifiedTime = modifiedTime;
    }
    if (createTime != null) {
      _result.createTime = createTime;
    }
    return _result;
  }
  factory WorkspacePB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WorkspacePB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WorkspacePB clone() => WorkspacePB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WorkspacePB copyWith(void Function(WorkspacePB) updates) => super.copyWith((message) => updates(message as WorkspacePB)) as WorkspacePB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WorkspacePB create() => WorkspacePB._();
  WorkspacePB createEmptyInstance() => create();
  static $pb.PbList<WorkspacePB> createRepeated() => $pb.PbList<WorkspacePB>();
  @$core.pragma('dart2js:noInline')
  static WorkspacePB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WorkspacePB>(create);
  static WorkspacePB? _defaultInstance;

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
  $0.RepeatedAppPB get apps => $_getN(3);
  @$pb.TagNumber(4)
  set apps($0.RepeatedAppPB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasApps() => $_has(3);
  @$pb.TagNumber(4)
  void clearApps() => clearField(4);
  @$pb.TagNumber(4)
  $0.RepeatedAppPB ensureApps() => $_ensure(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get modifiedTime => $_getI64(4);
  @$pb.TagNumber(5)
  set modifiedTime($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasModifiedTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedTime() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createTime => $_getI64(5);
  @$pb.TagNumber(6)
  set createTime($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasCreateTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreateTime() => clearField(6);
}

class RepeatedWorkspacePB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedWorkspacePB', createEmptyInstance: create)
    ..pc<WorkspacePB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: WorkspacePB.create)
    ..hasRequiredFields = false
  ;

  RepeatedWorkspacePB._() : super();
  factory RepeatedWorkspacePB({
    $core.Iterable<WorkspacePB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedWorkspacePB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedWorkspacePB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedWorkspacePB clone() => RepeatedWorkspacePB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedWorkspacePB copyWith(void Function(RepeatedWorkspacePB) updates) => super.copyWith((message) => updates(message as RepeatedWorkspacePB)) as RepeatedWorkspacePB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedWorkspacePB create() => RepeatedWorkspacePB._();
  RepeatedWorkspacePB createEmptyInstance() => create();
  static $pb.PbList<RepeatedWorkspacePB> createRepeated() => $pb.PbList<RepeatedWorkspacePB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedWorkspacePB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedWorkspacePB>(create);
  static RepeatedWorkspacePB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<WorkspacePB> get items => $_getList(0);
}

class CreateWorkspacePayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateWorkspacePayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  CreateWorkspacePayloadPB._() : super();
  factory CreateWorkspacePayloadPB({
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
  factory CreateWorkspacePayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateWorkspacePayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateWorkspacePayloadPB clone() => CreateWorkspacePayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateWorkspacePayloadPB copyWith(void Function(CreateWorkspacePayloadPB) updates) => super.copyWith((message) => updates(message as CreateWorkspacePayloadPB)) as CreateWorkspacePayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateWorkspacePayloadPB create() => CreateWorkspacePayloadPB._();
  CreateWorkspacePayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateWorkspacePayloadPB> createRepeated() => $pb.PbList<CreateWorkspacePayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateWorkspacePayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateWorkspacePayloadPB>(create);
  static CreateWorkspacePayloadPB? _defaultInstance;

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

enum WorkspaceIdPB_OneOfValue {
  value, 
  notSet
}

class WorkspaceIdPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, WorkspaceIdPB_OneOfValue> _WorkspaceIdPB_OneOfValueByTag = {
    1 : WorkspaceIdPB_OneOfValue.value,
    0 : WorkspaceIdPB_OneOfValue.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WorkspaceIdPB', createEmptyInstance: create)
    ..oo(0, [1])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  WorkspaceIdPB._() : super();
  factory WorkspaceIdPB({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory WorkspaceIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WorkspaceIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WorkspaceIdPB clone() => WorkspaceIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WorkspaceIdPB copyWith(void Function(WorkspaceIdPB) updates) => super.copyWith((message) => updates(message as WorkspaceIdPB)) as WorkspaceIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WorkspaceIdPB create() => WorkspaceIdPB._();
  WorkspaceIdPB createEmptyInstance() => create();
  static $pb.PbList<WorkspaceIdPB> createRepeated() => $pb.PbList<WorkspaceIdPB>();
  @$core.pragma('dart2js:noInline')
  static WorkspaceIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WorkspaceIdPB>(create);
  static WorkspaceIdPB? _defaultInstance;

  WorkspaceIdPB_OneOfValue whichOneOfValue() => _WorkspaceIdPB_OneOfValueByTag[$_whichOneof(0)]!;
  void clearOneOfValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

enum WorkspaceSettingPB_OneOfLatestView {
  latestView, 
  notSet
}

class WorkspaceSettingPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, WorkspaceSettingPB_OneOfLatestView> _WorkspaceSettingPB_OneOfLatestViewByTag = {
    2 : WorkspaceSettingPB_OneOfLatestView.latestView,
    0 : WorkspaceSettingPB_OneOfLatestView.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WorkspaceSettingPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOM<WorkspacePB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspace', subBuilder: WorkspacePB.create)
    ..aOM<$1.ViewPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'latestView', subBuilder: $1.ViewPB.create)
    ..hasRequiredFields = false
  ;

  WorkspaceSettingPB._() : super();
  factory WorkspaceSettingPB({
    WorkspacePB? workspace,
    $1.ViewPB? latestView,
  }) {
    final _result = create();
    if (workspace != null) {
      _result.workspace = workspace;
    }
    if (latestView != null) {
      _result.latestView = latestView;
    }
    return _result;
  }
  factory WorkspaceSettingPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WorkspaceSettingPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WorkspaceSettingPB clone() => WorkspaceSettingPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WorkspaceSettingPB copyWith(void Function(WorkspaceSettingPB) updates) => super.copyWith((message) => updates(message as WorkspaceSettingPB)) as WorkspaceSettingPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WorkspaceSettingPB create() => WorkspaceSettingPB._();
  WorkspaceSettingPB createEmptyInstance() => create();
  static $pb.PbList<WorkspaceSettingPB> createRepeated() => $pb.PbList<WorkspaceSettingPB>();
  @$core.pragma('dart2js:noInline')
  static WorkspaceSettingPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WorkspaceSettingPB>(create);
  static WorkspaceSettingPB? _defaultInstance;

  WorkspaceSettingPB_OneOfLatestView whichOneOfLatestView() => _WorkspaceSettingPB_OneOfLatestViewByTag[$_whichOneof(0)]!;
  void clearOneOfLatestView() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  WorkspacePB get workspace => $_getN(0);
  @$pb.TagNumber(1)
  set workspace(WorkspacePB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspace() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspace() => clearField(1);
  @$pb.TagNumber(1)
  WorkspacePB ensureWorkspace() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ViewPB get latestView => $_getN(1);
  @$pb.TagNumber(2)
  set latestView($1.ViewPB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatestView() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatestView() => clearField(2);
  @$pb.TagNumber(2)
  $1.ViewPB ensureLatestView() => $_ensure(1);
}

enum UpdateWorkspacePayloadPB_OneOfName {
  name, 
  notSet
}

enum UpdateWorkspacePayloadPB_OneOfDesc {
  desc, 
  notSet
}

class UpdateWorkspacePayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateWorkspacePayloadPB_OneOfName> _UpdateWorkspacePayloadPB_OneOfNameByTag = {
    2 : UpdateWorkspacePayloadPB_OneOfName.name,
    0 : UpdateWorkspacePayloadPB_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateWorkspacePayloadPB_OneOfDesc> _UpdateWorkspacePayloadPB_OneOfDescByTag = {
    3 : UpdateWorkspacePayloadPB_OneOfDesc.desc,
    0 : UpdateWorkspacePayloadPB_OneOfDesc.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateWorkspacePayloadPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  UpdateWorkspacePayloadPB._() : super();
  factory UpdateWorkspacePayloadPB({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
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
    return _result;
  }
  factory UpdateWorkspacePayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateWorkspacePayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateWorkspacePayloadPB clone() => UpdateWorkspacePayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateWorkspacePayloadPB copyWith(void Function(UpdateWorkspacePayloadPB) updates) => super.copyWith((message) => updates(message as UpdateWorkspacePayloadPB)) as UpdateWorkspacePayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspacePayloadPB create() => UpdateWorkspacePayloadPB._();
  UpdateWorkspacePayloadPB createEmptyInstance() => create();
  static $pb.PbList<UpdateWorkspacePayloadPB> createRepeated() => $pb.PbList<UpdateWorkspacePayloadPB>();
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspacePayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateWorkspacePayloadPB>(create);
  static UpdateWorkspacePayloadPB? _defaultInstance;

  UpdateWorkspacePayloadPB_OneOfName whichOneOfName() => _UpdateWorkspacePayloadPB_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateWorkspacePayloadPB_OneOfDesc whichOneOfDesc() => _UpdateWorkspacePayloadPB_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

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
}

