///
//  Generated code. Do not modify.
//  source: workspace.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'app.pb.dart' as $0;
import 'view.pb.dart' as $1;

class Workspace extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Workspace', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<$0.RepeatedApp>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'apps', subBuilder: $0.RepeatedApp.create)
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..hasRequiredFields = false
  ;

  Workspace._() : super();
  factory Workspace({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    $0.RepeatedApp? apps,
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

class RepeatedWorkspace extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedWorkspace', createEmptyInstance: create)
    ..pc<Workspace>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: Workspace.create)
    ..hasRequiredFields = false
  ;

  RepeatedWorkspace._() : super();
  factory RepeatedWorkspace({
    $core.Iterable<Workspace>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedWorkspace.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedWorkspace.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedWorkspace clone() => RepeatedWorkspace()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedWorkspace copyWith(void Function(RepeatedWorkspace) updates) => super.copyWith((message) => updates(message as RepeatedWorkspace)) as RepeatedWorkspace; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedWorkspace create() => RepeatedWorkspace._();
  RepeatedWorkspace createEmptyInstance() => create();
  static $pb.PbList<RepeatedWorkspace> createRepeated() => $pb.PbList<RepeatedWorkspace>();
  @$core.pragma('dart2js:noInline')
  static RepeatedWorkspace getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedWorkspace>(create);
  static RepeatedWorkspace? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Workspace> get items => $_getList(0);
}

class CreateWorkspacePayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateWorkspacePayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  CreateWorkspacePayload._() : super();
  factory CreateWorkspacePayload({
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
  factory CreateWorkspacePayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateWorkspacePayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateWorkspacePayload clone() => CreateWorkspacePayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateWorkspacePayload copyWith(void Function(CreateWorkspacePayload) updates) => super.copyWith((message) => updates(message as CreateWorkspacePayload)) as CreateWorkspacePayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateWorkspacePayload create() => CreateWorkspacePayload._();
  CreateWorkspacePayload createEmptyInstance() => create();
  static $pb.PbList<CreateWorkspacePayload> createRepeated() => $pb.PbList<CreateWorkspacePayload>();
  @$core.pragma('dart2js:noInline')
  static CreateWorkspacePayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateWorkspacePayload>(create);
  static CreateWorkspacePayload? _defaultInstance;

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

class CreateWorkspaceParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateWorkspaceParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  CreateWorkspaceParams._() : super();
  factory CreateWorkspaceParams({
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
  factory CreateWorkspaceParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateWorkspaceParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateWorkspaceParams clone() => CreateWorkspaceParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateWorkspaceParams copyWith(void Function(CreateWorkspaceParams) updates) => super.copyWith((message) => updates(message as CreateWorkspaceParams)) as CreateWorkspaceParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateWorkspaceParams create() => CreateWorkspaceParams._();
  CreateWorkspaceParams createEmptyInstance() => create();
  static $pb.PbList<CreateWorkspaceParams> createRepeated() => $pb.PbList<CreateWorkspaceParams>();
  @$core.pragma('dart2js:noInline')
  static CreateWorkspaceParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateWorkspaceParams>(create);
  static CreateWorkspaceParams? _defaultInstance;

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

enum WorkspaceId_OneOfValue {
  value, 
  notSet
}

class WorkspaceId extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, WorkspaceId_OneOfValue> _WorkspaceId_OneOfValueByTag = {
    1 : WorkspaceId_OneOfValue.value,
    0 : WorkspaceId_OneOfValue.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WorkspaceId', createEmptyInstance: create)
    ..oo(0, [1])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  WorkspaceId._() : super();
  factory WorkspaceId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory WorkspaceId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WorkspaceId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WorkspaceId clone() => WorkspaceId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WorkspaceId copyWith(void Function(WorkspaceId) updates) => super.copyWith((message) => updates(message as WorkspaceId)) as WorkspaceId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WorkspaceId create() => WorkspaceId._();
  WorkspaceId createEmptyInstance() => create();
  static $pb.PbList<WorkspaceId> createRepeated() => $pb.PbList<WorkspaceId>();
  @$core.pragma('dart2js:noInline')
  static WorkspaceId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WorkspaceId>(create);
  static WorkspaceId? _defaultInstance;

  WorkspaceId_OneOfValue whichOneOfValue() => _WorkspaceId_OneOfValueByTag[$_whichOneof(0)]!;
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

enum CurrentWorkspaceSetting_OneOfLatestView {
  latestView, 
  notSet
}

class CurrentWorkspaceSetting extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CurrentWorkspaceSetting_OneOfLatestView> _CurrentWorkspaceSetting_OneOfLatestViewByTag = {
    2 : CurrentWorkspaceSetting_OneOfLatestView.latestView,
    0 : CurrentWorkspaceSetting_OneOfLatestView.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CurrentWorkspaceSetting', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOM<Workspace>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspace', subBuilder: Workspace.create)
    ..aOM<$1.View>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'latestView', subBuilder: $1.View.create)
    ..hasRequiredFields = false
  ;

  CurrentWorkspaceSetting._() : super();
  factory CurrentWorkspaceSetting({
    Workspace? workspace,
    $1.View? latestView,
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
  factory CurrentWorkspaceSetting.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CurrentWorkspaceSetting.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CurrentWorkspaceSetting clone() => CurrentWorkspaceSetting()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CurrentWorkspaceSetting copyWith(void Function(CurrentWorkspaceSetting) updates) => super.copyWith((message) => updates(message as CurrentWorkspaceSetting)) as CurrentWorkspaceSetting; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CurrentWorkspaceSetting create() => CurrentWorkspaceSetting._();
  CurrentWorkspaceSetting createEmptyInstance() => create();
  static $pb.PbList<CurrentWorkspaceSetting> createRepeated() => $pb.PbList<CurrentWorkspaceSetting>();
  @$core.pragma('dart2js:noInline')
  static CurrentWorkspaceSetting getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CurrentWorkspaceSetting>(create);
  static CurrentWorkspaceSetting? _defaultInstance;

  CurrentWorkspaceSetting_OneOfLatestView whichOneOfLatestView() => _CurrentWorkspaceSetting_OneOfLatestViewByTag[$_whichOneof(0)]!;
  void clearOneOfLatestView() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Workspace get workspace => $_getN(0);
  @$pb.TagNumber(1)
  set workspace(Workspace v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspace() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspace() => clearField(1);
  @$pb.TagNumber(1)
  Workspace ensureWorkspace() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.View get latestView => $_getN(1);
  @$pb.TagNumber(2)
  set latestView($1.View v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatestView() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatestView() => clearField(2);
  @$pb.TagNumber(2)
  $1.View ensureLatestView() => $_ensure(1);
}

enum UpdateWorkspaceRequest_OneOfName {
  name, 
  notSet
}

enum UpdateWorkspaceRequest_OneOfDesc {
  desc, 
  notSet
}

class UpdateWorkspaceRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateWorkspaceRequest_OneOfName> _UpdateWorkspaceRequest_OneOfNameByTag = {
    2 : UpdateWorkspaceRequest_OneOfName.name,
    0 : UpdateWorkspaceRequest_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateWorkspaceRequest_OneOfDesc> _UpdateWorkspaceRequest_OneOfDescByTag = {
    3 : UpdateWorkspaceRequest_OneOfDesc.desc,
    0 : UpdateWorkspaceRequest_OneOfDesc.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateWorkspaceRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  UpdateWorkspaceRequest._() : super();
  factory UpdateWorkspaceRequest({
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
  factory UpdateWorkspaceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateWorkspaceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceRequest clone() => UpdateWorkspaceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceRequest copyWith(void Function(UpdateWorkspaceRequest) updates) => super.copyWith((message) => updates(message as UpdateWorkspaceRequest)) as UpdateWorkspaceRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceRequest create() => UpdateWorkspaceRequest._();
  UpdateWorkspaceRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateWorkspaceRequest> createRepeated() => $pb.PbList<UpdateWorkspaceRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateWorkspaceRequest>(create);
  static UpdateWorkspaceRequest? _defaultInstance;

  UpdateWorkspaceRequest_OneOfName whichOneOfName() => _UpdateWorkspaceRequest_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateWorkspaceRequest_OneOfDesc whichOneOfDesc() => _UpdateWorkspaceRequest_OneOfDescByTag[$_whichOneof(1)]!;
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

enum UpdateWorkspaceParams_OneOfName {
  name, 
  notSet
}

enum UpdateWorkspaceParams_OneOfDesc {
  desc, 
  notSet
}

class UpdateWorkspaceParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateWorkspaceParams_OneOfName> _UpdateWorkspaceParams_OneOfNameByTag = {
    2 : UpdateWorkspaceParams_OneOfName.name,
    0 : UpdateWorkspaceParams_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateWorkspaceParams_OneOfDesc> _UpdateWorkspaceParams_OneOfDescByTag = {
    3 : UpdateWorkspaceParams_OneOfDesc.desc,
    0 : UpdateWorkspaceParams_OneOfDesc.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateWorkspaceParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  UpdateWorkspaceParams._() : super();
  factory UpdateWorkspaceParams({
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
  factory UpdateWorkspaceParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateWorkspaceParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceParams clone() => UpdateWorkspaceParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceParams copyWith(void Function(UpdateWorkspaceParams) updates) => super.copyWith((message) => updates(message as UpdateWorkspaceParams)) as UpdateWorkspaceParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceParams create() => UpdateWorkspaceParams._();
  UpdateWorkspaceParams createEmptyInstance() => create();
  static $pb.PbList<UpdateWorkspaceParams> createRepeated() => $pb.PbList<UpdateWorkspaceParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateWorkspaceParams>(create);
  static UpdateWorkspaceParams? _defaultInstance;

  UpdateWorkspaceParams_OneOfName whichOneOfName() => _UpdateWorkspaceParams_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateWorkspaceParams_OneOfDesc whichOneOfDesc() => _UpdateWorkspaceParams_OneOfDescByTag[$_whichOneof(1)]!;
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

