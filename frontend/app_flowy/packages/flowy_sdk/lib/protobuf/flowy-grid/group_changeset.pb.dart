///
//  Generated code. Do not modify.
//  source: group_changeset.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'row_entities.pb.dart' as $0;
import 'group.pb.dart' as $1;

enum GroupRowsNotificationPB_OneOfGroupName {
  groupName, 
  notSet
}

class GroupRowsNotificationPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, GroupRowsNotificationPB_OneOfGroupName> _GroupRowsNotificationPB_OneOfGroupNameByTag = {
    2 : GroupRowsNotificationPB_OneOfGroupName.groupName,
    0 : GroupRowsNotificationPB_OneOfGroupName.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupRowsNotificationPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupName')
    ..pc<$0.InsertedRowPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedRows', $pb.PbFieldType.PM, subBuilder: $0.InsertedRowPB.create)
    ..pPS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedRows')
    ..pc<$0.RowPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedRows', $pb.PbFieldType.PM, subBuilder: $0.RowPB.create)
    ..hasRequiredFields = false
  ;

  GroupRowsNotificationPB._() : super();
  factory GroupRowsNotificationPB({
    $core.String? groupId,
    $core.String? groupName,
    $core.Iterable<$0.InsertedRowPB>? insertedRows,
    $core.Iterable<$core.String>? deletedRows,
    $core.Iterable<$0.RowPB>? updatedRows,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (groupName != null) {
      _result.groupName = groupName;
    }
    if (insertedRows != null) {
      _result.insertedRows.addAll(insertedRows);
    }
    if (deletedRows != null) {
      _result.deletedRows.addAll(deletedRows);
    }
    if (updatedRows != null) {
      _result.updatedRows.addAll(updatedRows);
    }
    return _result;
  }
  factory GroupRowsNotificationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupRowsNotificationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupRowsNotificationPB clone() => GroupRowsNotificationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupRowsNotificationPB copyWith(void Function(GroupRowsNotificationPB) updates) => super.copyWith((message) => updates(message as GroupRowsNotificationPB)) as GroupRowsNotificationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GroupRowsNotificationPB create() => GroupRowsNotificationPB._();
  GroupRowsNotificationPB createEmptyInstance() => create();
  static $pb.PbList<GroupRowsNotificationPB> createRepeated() => $pb.PbList<GroupRowsNotificationPB>();
  @$core.pragma('dart2js:noInline')
  static GroupRowsNotificationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupRowsNotificationPB>(create);
  static GroupRowsNotificationPB? _defaultInstance;

  GroupRowsNotificationPB_OneOfGroupName whichOneOfGroupName() => _GroupRowsNotificationPB_OneOfGroupNameByTag[$_whichOneof(0)]!;
  void clearOneOfGroupName() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupName => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupName() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupName() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$0.InsertedRowPB> get insertedRows => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.String> get deletedRows => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$0.RowPB> get updatedRows => $_getList(4);
}

class MoveGroupPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveGroupPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromGroupId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toGroupId')
    ..hasRequiredFields = false
  ;

  MoveGroupPayloadPB._() : super();
  factory MoveGroupPayloadPB({
    $core.String? viewId,
    $core.String? fromGroupId,
    $core.String? toGroupId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (fromGroupId != null) {
      _result.fromGroupId = fromGroupId;
    }
    if (toGroupId != null) {
      _result.toGroupId = toGroupId;
    }
    return _result;
  }
  factory MoveGroupPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveGroupPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveGroupPayloadPB clone() => MoveGroupPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveGroupPayloadPB copyWith(void Function(MoveGroupPayloadPB) updates) => super.copyWith((message) => updates(message as MoveGroupPayloadPB)) as MoveGroupPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveGroupPayloadPB create() => MoveGroupPayloadPB._();
  MoveGroupPayloadPB createEmptyInstance() => create();
  static $pb.PbList<MoveGroupPayloadPB> createRepeated() => $pb.PbList<MoveGroupPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static MoveGroupPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveGroupPayloadPB>(create);
  static MoveGroupPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromGroupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromGroupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFromGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromGroupId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get toGroupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set toGroupId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasToGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearToGroupId() => clearField(3);
}

class GroupViewChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupViewChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..pc<InsertedGroupPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedGroups', $pb.PbFieldType.PM, subBuilder: InsertedGroupPB.create)
    ..pc<$1.GroupPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'newGroups', $pb.PbFieldType.PM, subBuilder: $1.GroupPB.create)
    ..pPS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedGroups')
    ..pc<$1.GroupPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updateGroups', $pb.PbFieldType.PM, subBuilder: $1.GroupPB.create)
    ..hasRequiredFields = false
  ;

  GroupViewChangesetPB._() : super();
  factory GroupViewChangesetPB({
    $core.String? viewId,
    $core.Iterable<InsertedGroupPB>? insertedGroups,
    $core.Iterable<$1.GroupPB>? newGroups,
    $core.Iterable<$core.String>? deletedGroups,
    $core.Iterable<$1.GroupPB>? updateGroups,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (insertedGroups != null) {
      _result.insertedGroups.addAll(insertedGroups);
    }
    if (newGroups != null) {
      _result.newGroups.addAll(newGroups);
    }
    if (deletedGroups != null) {
      _result.deletedGroups.addAll(deletedGroups);
    }
    if (updateGroups != null) {
      _result.updateGroups.addAll(updateGroups);
    }
    return _result;
  }
  factory GroupViewChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupViewChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupViewChangesetPB clone() => GroupViewChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupViewChangesetPB copyWith(void Function(GroupViewChangesetPB) updates) => super.copyWith((message) => updates(message as GroupViewChangesetPB)) as GroupViewChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GroupViewChangesetPB create() => GroupViewChangesetPB._();
  GroupViewChangesetPB createEmptyInstance() => create();
  static $pb.PbList<GroupViewChangesetPB> createRepeated() => $pb.PbList<GroupViewChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static GroupViewChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupViewChangesetPB>(create);
  static GroupViewChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<InsertedGroupPB> get insertedGroups => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$1.GroupPB> get newGroups => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.String> get deletedGroups => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$1.GroupPB> get updateGroups => $_getList(4);
}

class InsertedGroupPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InsertedGroupPB', createEmptyInstance: create)
    ..aOM<$1.GroupPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'group', subBuilder: $1.GroupPB.create)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  InsertedGroupPB._() : super();
  factory InsertedGroupPB({
    $1.GroupPB? group,
    $core.int? index,
  }) {
    final _result = create();
    if (group != null) {
      _result.group = group;
    }
    if (index != null) {
      _result.index = index;
    }
    return _result;
  }
  factory InsertedGroupPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InsertedGroupPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InsertedGroupPB clone() => InsertedGroupPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InsertedGroupPB copyWith(void Function(InsertedGroupPB) updates) => super.copyWith((message) => updates(message as InsertedGroupPB)) as InsertedGroupPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InsertedGroupPB create() => InsertedGroupPB._();
  InsertedGroupPB createEmptyInstance() => create();
  static $pb.PbList<InsertedGroupPB> createRepeated() => $pb.PbList<InsertedGroupPB>();
  @$core.pragma('dart2js:noInline')
  static InsertedGroupPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InsertedGroupPB>(create);
  static InsertedGroupPB? _defaultInstance;

  @$pb.TagNumber(1)
  $1.GroupPB get group => $_getN(0);
  @$pb.TagNumber(1)
  set group($1.GroupPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroup() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroup() => clearField(1);
  @$pb.TagNumber(1)
  $1.GroupPB ensureGroup() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

