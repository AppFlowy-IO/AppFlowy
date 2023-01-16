///
//  Generated code. Do not modify.
//  source: field_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field_entities.pbenum.dart';

export 'field_entities.pbenum.dart';

class FieldPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<FieldType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..aOB(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isPrimary')
    ..hasRequiredFields = false
  ;

  FieldPB._() : super();
  factory FieldPB({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    FieldType? fieldType,
    $core.bool? frozen,
    $core.bool? visibility,
    $core.int? width,
    $core.bool? isPrimary,
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
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (frozen != null) {
      _result.frozen = frozen;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    if (width != null) {
      _result.width = width;
    }
    if (isPrimary != null) {
      _result.isPrimary = isPrimary;
    }
    return _result;
  }
  factory FieldPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldPB clone() => FieldPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldPB copyWith(void Function(FieldPB) updates) => super.copyWith((message) => updates(message as FieldPB)) as FieldPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldPB create() => FieldPB._();
  FieldPB createEmptyInstance() => create();
  static $pb.PbList<FieldPB> createRepeated() => $pb.PbList<FieldPB>();
  @$core.pragma('dart2js:noInline')
  static FieldPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldPB>(create);
  static FieldPB? _defaultInstance;

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
  FieldType get fieldType => $_getN(3);
  @$pb.TagNumber(4)
  set fieldType(FieldType v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasFieldType() => $_has(3);
  @$pb.TagNumber(4)
  void clearFieldType() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get frozen => $_getBF(4);
  @$pb.TagNumber(5)
  set frozen($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasFrozen() => $_has(4);
  @$pb.TagNumber(5)
  void clearFrozen() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get visibility => $_getBF(5);
  @$pb.TagNumber(6)
  set visibility($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasVisibility() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisibility() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get width => $_getIZ(6);
  @$pb.TagNumber(7)
  set width($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasWidth() => $_has(6);
  @$pb.TagNumber(7)
  void clearWidth() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isPrimary => $_getBF(7);
  @$pb.TagNumber(8)
  set isPrimary($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasIsPrimary() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsPrimary() => clearField(8);
}

class FieldIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  FieldIdPB._() : super();
  factory FieldIdPB({
    $core.String? fieldId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    return _result;
  }
  factory FieldIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldIdPB clone() => FieldIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldIdPB copyWith(void Function(FieldIdPB) updates) => super.copyWith((message) => updates(message as FieldIdPB)) as FieldIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldIdPB create() => FieldIdPB._();
  FieldIdPB createEmptyInstance() => create();
  static $pb.PbList<FieldIdPB> createRepeated() => $pb.PbList<FieldIdPB>();
  @$core.pragma('dart2js:noInline')
  static FieldIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldIdPB>(create);
  static FieldIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);
}

class GridFieldChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridFieldChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..pc<IndexFieldPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedFields', $pb.PbFieldType.PM, subBuilder: IndexFieldPB.create)
    ..pc<FieldIdPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedFields', $pb.PbFieldType.PM, subBuilder: FieldIdPB.create)
    ..pc<FieldPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedFields', $pb.PbFieldType.PM, subBuilder: FieldPB.create)
    ..hasRequiredFields = false
  ;

  GridFieldChangesetPB._() : super();
  factory GridFieldChangesetPB({
    $core.String? gridId,
    $core.Iterable<IndexFieldPB>? insertedFields,
    $core.Iterable<FieldIdPB>? deletedFields,
    $core.Iterable<FieldPB>? updatedFields,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (insertedFields != null) {
      _result.insertedFields.addAll(insertedFields);
    }
    if (deletedFields != null) {
      _result.deletedFields.addAll(deletedFields);
    }
    if (updatedFields != null) {
      _result.updatedFields.addAll(updatedFields);
    }
    return _result;
  }
  factory GridFieldChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridFieldChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridFieldChangesetPB clone() => GridFieldChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridFieldChangesetPB copyWith(void Function(GridFieldChangesetPB) updates) => super.copyWith((message) => updates(message as GridFieldChangesetPB)) as GridFieldChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridFieldChangesetPB create() => GridFieldChangesetPB._();
  GridFieldChangesetPB createEmptyInstance() => create();
  static $pb.PbList<GridFieldChangesetPB> createRepeated() => $pb.PbList<GridFieldChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static GridFieldChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridFieldChangesetPB>(create);
  static GridFieldChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<IndexFieldPB> get insertedFields => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<FieldIdPB> get deletedFields => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<FieldPB> get updatedFields => $_getList(3);
}

class IndexFieldPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'IndexFieldPB', createEmptyInstance: create)
    ..aOM<FieldPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'field', subBuilder: FieldPB.create)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  IndexFieldPB._() : super();
  factory IndexFieldPB({
    FieldPB? field_1,
    $core.int? index,
  }) {
    final _result = create();
    if (field_1 != null) {
      _result.field_1 = field_1;
    }
    if (index != null) {
      _result.index = index;
    }
    return _result;
  }
  factory IndexFieldPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IndexFieldPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IndexFieldPB clone() => IndexFieldPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IndexFieldPB copyWith(void Function(IndexFieldPB) updates) => super.copyWith((message) => updates(message as IndexFieldPB)) as IndexFieldPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static IndexFieldPB create() => IndexFieldPB._();
  IndexFieldPB createEmptyInstance() => create();
  static $pb.PbList<IndexFieldPB> createRepeated() => $pb.PbList<IndexFieldPB>();
  @$core.pragma('dart2js:noInline')
  static IndexFieldPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexFieldPB>(create);
  static IndexFieldPB? _defaultInstance;

  @$pb.TagNumber(1)
  FieldPB get field_1 => $_getN(0);
  @$pb.TagNumber(1)
  set field_1(FieldPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => clearField(1);
  @$pb.TagNumber(1)
  FieldPB ensureField_1() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

enum CreateFieldPayloadPB_OneOfTypeOptionData {
  typeOptionData, 
  notSet
}

class CreateFieldPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateFieldPayloadPB_OneOfTypeOptionData> _CreateFieldPayloadPB_OneOfTypeOptionDataByTag = {
    3 : CreateFieldPayloadPB_OneOfTypeOptionData.typeOptionData,
    0 : CreateFieldPayloadPB_OneOfTypeOptionData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateFieldPayloadPB', createEmptyInstance: create)
    ..oo(0, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..e<FieldType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  CreateFieldPayloadPB._() : super();
  factory CreateFieldPayloadPB({
    $core.String? gridId,
    FieldType? fieldType,
    $core.List<$core.int>? typeOptionData,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (typeOptionData != null) {
      _result.typeOptionData = typeOptionData;
    }
    return _result;
  }
  factory CreateFieldPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateFieldPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateFieldPayloadPB clone() => CreateFieldPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateFieldPayloadPB copyWith(void Function(CreateFieldPayloadPB) updates) => super.copyWith((message) => updates(message as CreateFieldPayloadPB)) as CreateFieldPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateFieldPayloadPB create() => CreateFieldPayloadPB._();
  CreateFieldPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateFieldPayloadPB> createRepeated() => $pb.PbList<CreateFieldPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateFieldPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateFieldPayloadPB>(create);
  static CreateFieldPayloadPB? _defaultInstance;

  CreateFieldPayloadPB_OneOfTypeOptionData whichOneOfTypeOptionData() => _CreateFieldPayloadPB_OneOfTypeOptionDataByTag[$_whichOneof(0)]!;
  void clearOneOfTypeOptionData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  FieldType get fieldType => $_getN(1);
  @$pb.TagNumber(2)
  set fieldType(FieldType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldType() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldType() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get typeOptionData => $_getN(2);
  @$pb.TagNumber(3)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTypeOptionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearTypeOptionData() => clearField(3);
}

class EditFieldChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EditFieldChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createIfNotExist')
    ..hasRequiredFields = false
  ;

  EditFieldChangesetPB._() : super();
  factory EditFieldChangesetPB({
    $core.String? gridId,
    $core.String? fieldId,
    FieldType? fieldType,
    $core.bool? createIfNotExist,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (createIfNotExist != null) {
      _result.createIfNotExist = createIfNotExist;
    }
    return _result;
  }
  factory EditFieldChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EditFieldChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EditFieldChangesetPB clone() => EditFieldChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EditFieldChangesetPB copyWith(void Function(EditFieldChangesetPB) updates) => super.copyWith((message) => updates(message as EditFieldChangesetPB)) as EditFieldChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EditFieldChangesetPB create() => EditFieldChangesetPB._();
  EditFieldChangesetPB createEmptyInstance() => create();
  static $pb.PbList<EditFieldChangesetPB> createRepeated() => $pb.PbList<EditFieldChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static EditFieldChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EditFieldChangesetPB>(create);
  static EditFieldChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldId() => clearField(2);

  @$pb.TagNumber(3)
  FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType(FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get createIfNotExist => $_getBF(3);
  @$pb.TagNumber(4)
  set createIfNotExist($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreateIfNotExist() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreateIfNotExist() => clearField(4);
}

class TypeOptionPathPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TypeOptionPathPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..hasRequiredFields = false
  ;

  TypeOptionPathPB._() : super();
  factory TypeOptionPathPB({
    $core.String? gridId,
    $core.String? fieldId,
    FieldType? fieldType,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    return _result;
  }
  factory TypeOptionPathPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TypeOptionPathPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TypeOptionPathPB clone() => TypeOptionPathPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TypeOptionPathPB copyWith(void Function(TypeOptionPathPB) updates) => super.copyWith((message) => updates(message as TypeOptionPathPB)) as TypeOptionPathPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TypeOptionPathPB create() => TypeOptionPathPB._();
  TypeOptionPathPB createEmptyInstance() => create();
  static $pb.PbList<TypeOptionPathPB> createRepeated() => $pb.PbList<TypeOptionPathPB>();
  @$core.pragma('dart2js:noInline')
  static TypeOptionPathPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypeOptionPathPB>(create);
  static TypeOptionPathPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldId() => clearField(2);

  @$pb.TagNumber(3)
  FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType(FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);
}

class TypeOptionPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TypeOptionPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<FieldPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'field', subBuilder: FieldPB.create)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  TypeOptionPB._() : super();
  factory TypeOptionPB({
    $core.String? gridId,
    FieldPB? field_2,
    $core.List<$core.int>? typeOptionData,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (field_2 != null) {
      _result.field_2 = field_2;
    }
    if (typeOptionData != null) {
      _result.typeOptionData = typeOptionData;
    }
    return _result;
  }
  factory TypeOptionPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TypeOptionPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TypeOptionPB clone() => TypeOptionPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TypeOptionPB copyWith(void Function(TypeOptionPB) updates) => super.copyWith((message) => updates(message as TypeOptionPB)) as TypeOptionPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TypeOptionPB create() => TypeOptionPB._();
  TypeOptionPB createEmptyInstance() => create();
  static $pb.PbList<TypeOptionPB> createRepeated() => $pb.PbList<TypeOptionPB>();
  @$core.pragma('dart2js:noInline')
  static TypeOptionPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypeOptionPB>(create);
  static TypeOptionPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  FieldPB get field_2 => $_getN(1);
  @$pb.TagNumber(2)
  set field_2(FieldPB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasField_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearField_2() => clearField(2);
  @$pb.TagNumber(2)
  FieldPB ensureField_2() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get typeOptionData => $_getN(2);
  @$pb.TagNumber(3)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTypeOptionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearTypeOptionData() => clearField(3);
}

class RepeatedFieldPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedFieldPB', createEmptyInstance: create)
    ..pc<FieldPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: FieldPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedFieldPB._() : super();
  factory RepeatedFieldPB({
    $core.Iterable<FieldPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedFieldPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedFieldPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedFieldPB clone() => RepeatedFieldPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedFieldPB copyWith(void Function(RepeatedFieldPB) updates) => super.copyWith((message) => updates(message as RepeatedFieldPB)) as RepeatedFieldPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedFieldPB create() => RepeatedFieldPB._();
  RepeatedFieldPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedFieldPB> createRepeated() => $pb.PbList<RepeatedFieldPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedFieldPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedFieldPB>(create);
  static RepeatedFieldPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FieldPB> get items => $_getList(0);
}

class RepeatedFieldIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedFieldIdPB', createEmptyInstance: create)
    ..pc<FieldIdPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: FieldIdPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedFieldIdPB._() : super();
  factory RepeatedFieldIdPB({
    $core.Iterable<FieldIdPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedFieldIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedFieldIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedFieldIdPB clone() => RepeatedFieldIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedFieldIdPB copyWith(void Function(RepeatedFieldIdPB) updates) => super.copyWith((message) => updates(message as RepeatedFieldIdPB)) as RepeatedFieldIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedFieldIdPB create() => RepeatedFieldIdPB._();
  RepeatedFieldIdPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedFieldIdPB> createRepeated() => $pb.PbList<RepeatedFieldIdPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedFieldIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedFieldIdPB>(create);
  static RepeatedFieldIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FieldIdPB> get items => $_getList(0);
}

class TypeOptionChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TypeOptionChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  TypeOptionChangesetPB._() : super();
  factory TypeOptionChangesetPB({
    $core.String? gridId,
    $core.String? fieldId,
    $core.List<$core.int>? typeOptionData,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (typeOptionData != null) {
      _result.typeOptionData = typeOptionData;
    }
    return _result;
  }
  factory TypeOptionChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TypeOptionChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TypeOptionChangesetPB clone() => TypeOptionChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TypeOptionChangesetPB copyWith(void Function(TypeOptionChangesetPB) updates) => super.copyWith((message) => updates(message as TypeOptionChangesetPB)) as TypeOptionChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TypeOptionChangesetPB create() => TypeOptionChangesetPB._();
  TypeOptionChangesetPB createEmptyInstance() => create();
  static $pb.PbList<TypeOptionChangesetPB> createRepeated() => $pb.PbList<TypeOptionChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static TypeOptionChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypeOptionChangesetPB>(create);
  static TypeOptionChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get typeOptionData => $_getN(2);
  @$pb.TagNumber(3)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTypeOptionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearTypeOptionData() => clearField(3);
}

enum GetFieldPayloadPB_OneOfFieldIds {
  fieldIds, 
  notSet
}

class GetFieldPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, GetFieldPayloadPB_OneOfFieldIds> _GetFieldPayloadPB_OneOfFieldIdsByTag = {
    2 : GetFieldPayloadPB_OneOfFieldIds.fieldIds,
    0 : GetFieldPayloadPB_OneOfFieldIds.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetFieldPayloadPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<RepeatedFieldIdPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldIds', subBuilder: RepeatedFieldIdPB.create)
    ..hasRequiredFields = false
  ;

  GetFieldPayloadPB._() : super();
  factory GetFieldPayloadPB({
    $core.String? gridId,
    RepeatedFieldIdPB? fieldIds,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldIds != null) {
      _result.fieldIds = fieldIds;
    }
    return _result;
  }
  factory GetFieldPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetFieldPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetFieldPayloadPB clone() => GetFieldPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetFieldPayloadPB copyWith(void Function(GetFieldPayloadPB) updates) => super.copyWith((message) => updates(message as GetFieldPayloadPB)) as GetFieldPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetFieldPayloadPB create() => GetFieldPayloadPB._();
  GetFieldPayloadPB createEmptyInstance() => create();
  static $pb.PbList<GetFieldPayloadPB> createRepeated() => $pb.PbList<GetFieldPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static GetFieldPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetFieldPayloadPB>(create);
  static GetFieldPayloadPB? _defaultInstance;

  GetFieldPayloadPB_OneOfFieldIds whichOneOfFieldIds() => _GetFieldPayloadPB_OneOfFieldIdsByTag[$_whichOneof(0)]!;
  void clearOneOfFieldIds() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  RepeatedFieldIdPB get fieldIds => $_getN(1);
  @$pb.TagNumber(2)
  set fieldIds(RepeatedFieldIdPB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldIds() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldIds() => clearField(2);
  @$pb.TagNumber(2)
  RepeatedFieldIdPB ensureFieldIds() => $_ensure(1);
}

enum FieldChangesetPB_OneOfName {
  name, 
  notSet
}

enum FieldChangesetPB_OneOfDesc {
  desc, 
  notSet
}

enum FieldChangesetPB_OneOfFieldType {
  fieldType, 
  notSet
}

enum FieldChangesetPB_OneOfFrozen {
  frozen, 
  notSet
}

enum FieldChangesetPB_OneOfVisibility {
  visibility, 
  notSet
}

enum FieldChangesetPB_OneOfWidth {
  width, 
  notSet
}

class FieldChangesetPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, FieldChangesetPB_OneOfName> _FieldChangesetPB_OneOfNameByTag = {
    3 : FieldChangesetPB_OneOfName.name,
    0 : FieldChangesetPB_OneOfName.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPB_OneOfDesc> _FieldChangesetPB_OneOfDescByTag = {
    4 : FieldChangesetPB_OneOfDesc.desc,
    0 : FieldChangesetPB_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPB_OneOfFieldType> _FieldChangesetPB_OneOfFieldTypeByTag = {
    5 : FieldChangesetPB_OneOfFieldType.fieldType,
    0 : FieldChangesetPB_OneOfFieldType.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPB_OneOfFrozen> _FieldChangesetPB_OneOfFrozenByTag = {
    6 : FieldChangesetPB_OneOfFrozen.frozen,
    0 : FieldChangesetPB_OneOfFrozen.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPB_OneOfVisibility> _FieldChangesetPB_OneOfVisibilityByTag = {
    7 : FieldChangesetPB_OneOfVisibility.visibility,
    0 : FieldChangesetPB_OneOfVisibility.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPB_OneOfWidth> _FieldChangesetPB_OneOfWidthByTag = {
    8 : FieldChangesetPB_OneOfWidth.width,
    0 : FieldChangesetPB_OneOfWidth.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldChangesetPB', createEmptyInstance: create)
    ..oo(0, [3])
    ..oo(1, [4])
    ..oo(2, [5])
    ..oo(3, [6])
    ..oo(4, [7])
    ..oo(5, [8])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<FieldType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..aOB(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..a<$core.int>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  FieldChangesetPB._() : super();
  factory FieldChangesetPB({
    $core.String? fieldId,
    $core.String? gridId,
    $core.String? name,
    $core.String? desc,
    FieldType? fieldType,
    $core.bool? frozen,
    $core.bool? visibility,
    $core.int? width,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (frozen != null) {
      _result.frozen = frozen;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    if (width != null) {
      _result.width = width;
    }
    return _result;
  }
  factory FieldChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldChangesetPB clone() => FieldChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldChangesetPB copyWith(void Function(FieldChangesetPB) updates) => super.copyWith((message) => updates(message as FieldChangesetPB)) as FieldChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldChangesetPB create() => FieldChangesetPB._();
  FieldChangesetPB createEmptyInstance() => create();
  static $pb.PbList<FieldChangesetPB> createRepeated() => $pb.PbList<FieldChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static FieldChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldChangesetPB>(create);
  static FieldChangesetPB? _defaultInstance;

  FieldChangesetPB_OneOfName whichOneOfName() => _FieldChangesetPB_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  FieldChangesetPB_OneOfDesc whichOneOfDesc() => _FieldChangesetPB_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  FieldChangesetPB_OneOfFieldType whichOneOfFieldType() => _FieldChangesetPB_OneOfFieldTypeByTag[$_whichOneof(2)]!;
  void clearOneOfFieldType() => clearField($_whichOneof(2));

  FieldChangesetPB_OneOfFrozen whichOneOfFrozen() => _FieldChangesetPB_OneOfFrozenByTag[$_whichOneof(3)]!;
  void clearOneOfFrozen() => clearField($_whichOneof(3));

  FieldChangesetPB_OneOfVisibility whichOneOfVisibility() => _FieldChangesetPB_OneOfVisibilityByTag[$_whichOneof(4)]!;
  void clearOneOfVisibility() => clearField($_whichOneof(4));

  FieldChangesetPB_OneOfWidth whichOneOfWidth() => _FieldChangesetPB_OneOfWidthByTag[$_whichOneof(5)]!;
  void clearOneOfWidth() => clearField($_whichOneof(5));

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get gridId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gridId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get desc => $_getSZ(3);
  @$pb.TagNumber(4)
  set desc($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDesc() => $_has(3);
  @$pb.TagNumber(4)
  void clearDesc() => clearField(4);

  @$pb.TagNumber(5)
  FieldType get fieldType => $_getN(4);
  @$pb.TagNumber(5)
  set fieldType(FieldType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasFieldType() => $_has(4);
  @$pb.TagNumber(5)
  void clearFieldType() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get frozen => $_getBF(5);
  @$pb.TagNumber(6)
  set frozen($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasFrozen() => $_has(5);
  @$pb.TagNumber(6)
  void clearFrozen() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get visibility => $_getBF(6);
  @$pb.TagNumber(7)
  set visibility($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasVisibility() => $_has(6);
  @$pb.TagNumber(7)
  void clearVisibility() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get width => $_getIZ(7);
  @$pb.TagNumber(8)
  set width($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasWidth() => $_has(7);
  @$pb.TagNumber(8)
  void clearWidth() => clearField(8);
}

class DuplicateFieldPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DuplicateFieldPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..hasRequiredFields = false
  ;

  DuplicateFieldPayloadPB._() : super();
  factory DuplicateFieldPayloadPB({
    $core.String? fieldId,
    $core.String? gridId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    return _result;
  }
  factory DuplicateFieldPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DuplicateFieldPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DuplicateFieldPayloadPB clone() => DuplicateFieldPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DuplicateFieldPayloadPB copyWith(void Function(DuplicateFieldPayloadPB) updates) => super.copyWith((message) => updates(message as DuplicateFieldPayloadPB)) as DuplicateFieldPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DuplicateFieldPayloadPB create() => DuplicateFieldPayloadPB._();
  DuplicateFieldPayloadPB createEmptyInstance() => create();
  static $pb.PbList<DuplicateFieldPayloadPB> createRepeated() => $pb.PbList<DuplicateFieldPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static DuplicateFieldPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DuplicateFieldPayloadPB>(create);
  static DuplicateFieldPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get gridId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gridId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridId() => clearField(2);
}

class GridFieldIdentifierPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridFieldIdentifierPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..hasRequiredFields = false
  ;

  GridFieldIdentifierPayloadPB._() : super();
  factory GridFieldIdentifierPayloadPB({
    $core.String? fieldId,
    $core.String? gridId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    return _result;
  }
  factory GridFieldIdentifierPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridFieldIdentifierPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridFieldIdentifierPayloadPB clone() => GridFieldIdentifierPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridFieldIdentifierPayloadPB copyWith(void Function(GridFieldIdentifierPayloadPB) updates) => super.copyWith((message) => updates(message as GridFieldIdentifierPayloadPB)) as GridFieldIdentifierPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridFieldIdentifierPayloadPB create() => GridFieldIdentifierPayloadPB._();
  GridFieldIdentifierPayloadPB createEmptyInstance() => create();
  static $pb.PbList<GridFieldIdentifierPayloadPB> createRepeated() => $pb.PbList<GridFieldIdentifierPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static GridFieldIdentifierPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridFieldIdentifierPayloadPB>(create);
  static GridFieldIdentifierPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get gridId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gridId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridId() => clearField(2);
}

class DeleteFieldPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteFieldPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..hasRequiredFields = false
  ;

  DeleteFieldPayloadPB._() : super();
  factory DeleteFieldPayloadPB({
    $core.String? fieldId,
    $core.String? gridId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    return _result;
  }
  factory DeleteFieldPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteFieldPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteFieldPayloadPB clone() => DeleteFieldPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteFieldPayloadPB copyWith(void Function(DeleteFieldPayloadPB) updates) => super.copyWith((message) => updates(message as DeleteFieldPayloadPB)) as DeleteFieldPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteFieldPayloadPB create() => DeleteFieldPayloadPB._();
  DeleteFieldPayloadPB createEmptyInstance() => create();
  static $pb.PbList<DeleteFieldPayloadPB> createRepeated() => $pb.PbList<DeleteFieldPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static DeleteFieldPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteFieldPayloadPB>(create);
  static DeleteFieldPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get gridId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gridId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridId() => clearField(2);
}

