///
//  Generated code. Do not modify.
//  source: group.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'row_entities.pb.dart' as $0;

import 'field_entities.pbenum.dart' as $1;

enum CreateBoardCardPayloadPB_OneOfStartRowId {
  startRowId, 
  notSet
}

class CreateBoardCardPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateBoardCardPayloadPB_OneOfStartRowId> _CreateBoardCardPayloadPB_OneOfStartRowIdByTag = {
    3 : CreateBoardCardPayloadPB_OneOfStartRowId.startRowId,
    0 : CreateBoardCardPayloadPB_OneOfStartRowId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateBoardCardPayloadPB', createEmptyInstance: create)
    ..oo(0, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startRowId')
    ..hasRequiredFields = false
  ;

  CreateBoardCardPayloadPB._() : super();
  factory CreateBoardCardPayloadPB({
    $core.String? gridId,
    $core.String? groupId,
    $core.String? startRowId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (startRowId != null) {
      _result.startRowId = startRowId;
    }
    return _result;
  }
  factory CreateBoardCardPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateBoardCardPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateBoardCardPayloadPB clone() => CreateBoardCardPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateBoardCardPayloadPB copyWith(void Function(CreateBoardCardPayloadPB) updates) => super.copyWith((message) => updates(message as CreateBoardCardPayloadPB)) as CreateBoardCardPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateBoardCardPayloadPB create() => CreateBoardCardPayloadPB._();
  CreateBoardCardPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateBoardCardPayloadPB> createRepeated() => $pb.PbList<CreateBoardCardPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateBoardCardPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateBoardCardPayloadPB>(create);
  static CreateBoardCardPayloadPB? _defaultInstance;

  CreateBoardCardPayloadPB_OneOfStartRowId whichOneOfStartRowId() => _CreateBoardCardPayloadPB_OneOfStartRowIdByTag[$_whichOneof(0)]!;
  void clearOneOfStartRowId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get startRowId => $_getSZ(2);
  @$pb.TagNumber(3)
  set startRowId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStartRowId() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartRowId() => clearField(3);
}

class GroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupConfigurationPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  GroupConfigurationPB._() : super();
  factory GroupConfigurationPB({
    $core.String? id,
    $core.String? fieldId,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    return _result;
  }
  factory GroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupConfigurationPB clone() => GroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupConfigurationPB copyWith(void Function(GroupConfigurationPB) updates) => super.copyWith((message) => updates(message as GroupConfigurationPB)) as GroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GroupConfigurationPB create() => GroupConfigurationPB._();
  GroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<GroupConfigurationPB> createRepeated() => $pb.PbList<GroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static GroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupConfigurationPB>(create);
  static GroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldId() => clearField(2);
}

class RepeatedGroupPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedGroupPB', createEmptyInstance: create)
    ..pc<GroupPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: GroupPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedGroupPB._() : super();
  factory RepeatedGroupPB({
    $core.Iterable<GroupPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedGroupPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedGroupPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedGroupPB clone() => RepeatedGroupPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedGroupPB copyWith(void Function(RepeatedGroupPB) updates) => super.copyWith((message) => updates(message as RepeatedGroupPB)) as RepeatedGroupPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedGroupPB create() => RepeatedGroupPB._();
  RepeatedGroupPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedGroupPB> createRepeated() => $pb.PbList<RepeatedGroupPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedGroupPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedGroupPB>(create);
  static RepeatedGroupPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GroupPB> get items => $_getList(0);
}

class GroupPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..pc<$0.RowPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rows', $pb.PbFieldType.PM, subBuilder: $0.RowPB.create)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isDefault')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isVisible')
    ..hasRequiredFields = false
  ;

  GroupPB._() : super();
  factory GroupPB({
    $core.String? fieldId,
    $core.String? groupId,
    $core.String? desc,
    $core.Iterable<$0.RowPB>? rows,
    $core.bool? isDefault,
    $core.bool? isVisible,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (rows != null) {
      _result.rows.addAll(rows);
    }
    if (isDefault != null) {
      _result.isDefault = isDefault;
    }
    if (isVisible != null) {
      _result.isVisible = isVisible;
    }
    return _result;
  }
  factory GroupPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupPB clone() => GroupPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupPB copyWith(void Function(GroupPB) updates) => super.copyWith((message) => updates(message as GroupPB)) as GroupPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GroupPB create() => GroupPB._();
  GroupPB createEmptyInstance() => create();
  static $pb.PbList<GroupPB> createRepeated() => $pb.PbList<GroupPB>();
  @$core.pragma('dart2js:noInline')
  static GroupPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupPB>(create);
  static GroupPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$0.RowPB> get rows => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get isDefault => $_getBF(4);
  @$pb.TagNumber(5)
  set isDefault($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsDefault() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsDefault() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isVisible => $_getBF(5);
  @$pb.TagNumber(6)
  set isVisible($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasIsVisible() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsVisible() => clearField(6);
}

class RepeatedGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedGroupConfigurationPB', createEmptyInstance: create)
    ..pc<GroupConfigurationPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: GroupConfigurationPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedGroupConfigurationPB._() : super();
  factory RepeatedGroupConfigurationPB({
    $core.Iterable<GroupConfigurationPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedGroupConfigurationPB clone() => RepeatedGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedGroupConfigurationPB copyWith(void Function(RepeatedGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as RepeatedGroupConfigurationPB)) as RepeatedGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedGroupConfigurationPB create() => RepeatedGroupConfigurationPB._();
  RepeatedGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedGroupConfigurationPB> createRepeated() => $pb.PbList<RepeatedGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedGroupConfigurationPB>(create);
  static RepeatedGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GroupConfigurationPB> get items => $_getList(0);
}

class InsertGroupPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InsertGroupPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$1.FieldType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $1.FieldType.RichText, valueOf: $1.FieldType.valueOf, enumValues: $1.FieldType.values)
    ..hasRequiredFields = false
  ;

  InsertGroupPayloadPB._() : super();
  factory InsertGroupPayloadPB({
    $core.String? fieldId,
    $1.FieldType? fieldType,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    return _result;
  }
  factory InsertGroupPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InsertGroupPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InsertGroupPayloadPB clone() => InsertGroupPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InsertGroupPayloadPB copyWith(void Function(InsertGroupPayloadPB) updates) => super.copyWith((message) => updates(message as InsertGroupPayloadPB)) as InsertGroupPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InsertGroupPayloadPB create() => InsertGroupPayloadPB._();
  InsertGroupPayloadPB createEmptyInstance() => create();
  static $pb.PbList<InsertGroupPayloadPB> createRepeated() => $pb.PbList<InsertGroupPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static InsertGroupPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InsertGroupPayloadPB>(create);
  static InsertGroupPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $1.FieldType get fieldType => $_getN(1);
  @$pb.TagNumber(2)
  set fieldType($1.FieldType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldType() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldType() => clearField(2);
}

class DeleteGroupPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteGroupPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..e<$1.FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $1.FieldType.RichText, valueOf: $1.FieldType.valueOf, enumValues: $1.FieldType.values)
    ..hasRequiredFields = false
  ;

  DeleteGroupPayloadPB._() : super();
  factory DeleteGroupPayloadPB({
    $core.String? fieldId,
    $core.String? groupId,
    $1.FieldType? fieldType,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    return _result;
  }
  factory DeleteGroupPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteGroupPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteGroupPayloadPB clone() => DeleteGroupPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteGroupPayloadPB copyWith(void Function(DeleteGroupPayloadPB) updates) => super.copyWith((message) => updates(message as DeleteGroupPayloadPB)) as DeleteGroupPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteGroupPayloadPB create() => DeleteGroupPayloadPB._();
  DeleteGroupPayloadPB createEmptyInstance() => create();
  static $pb.PbList<DeleteGroupPayloadPB> createRepeated() => $pb.PbList<DeleteGroupPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static DeleteGroupPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteGroupPayloadPB>(create);
  static DeleteGroupPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);

  @$pb.TagNumber(3)
  $1.FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType($1.FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);
}

