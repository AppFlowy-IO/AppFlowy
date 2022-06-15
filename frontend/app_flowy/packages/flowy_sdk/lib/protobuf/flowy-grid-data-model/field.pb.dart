///
//  Generated code. Do not modify.
//  source: field.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field.pbenum.dart';

export 'field.pbenum.dart';

class Field extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Field', createEmptyInstance: create)
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

  Field._() : super();
  factory Field({
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
  factory Field.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Field.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Field clone() => Field()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Field copyWith(void Function(Field) updates) => super.copyWith((message) => updates(message as Field)) as Field; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Field create() => Field._();
  Field createEmptyInstance() => create();
  static $pb.PbList<Field> createRepeated() => $pb.PbList<Field>();
  @$core.pragma('dart2js:noInline')
  static Field getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Field>(create);
  static Field? _defaultInstance;

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

class FieldOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldOrder', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  FieldOrder._() : super();
  factory FieldOrder({
    $core.String? fieldId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    return _result;
  }
  factory FieldOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldOrder clone() => FieldOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldOrder copyWith(void Function(FieldOrder) updates) => super.copyWith((message) => updates(message as FieldOrder)) as FieldOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldOrder create() => FieldOrder._();
  FieldOrder createEmptyInstance() => create();
  static $pb.PbList<FieldOrder> createRepeated() => $pb.PbList<FieldOrder>();
  @$core.pragma('dart2js:noInline')
  static FieldOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldOrder>(create);
  static FieldOrder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);
}

class GridFieldChangeset extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridFieldChangeset', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..pc<IndexField>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedFields', $pb.PbFieldType.PM, subBuilder: IndexField.create)
    ..pc<FieldOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedFields', $pb.PbFieldType.PM, subBuilder: FieldOrder.create)
    ..pc<Field>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedFields', $pb.PbFieldType.PM, subBuilder: Field.create)
    ..hasRequiredFields = false
  ;

  GridFieldChangeset._() : super();
  factory GridFieldChangeset({
    $core.String? gridId,
    $core.Iterable<IndexField>? insertedFields,
    $core.Iterable<FieldOrder>? deletedFields,
    $core.Iterable<Field>? updatedFields,
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
  factory GridFieldChangeset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridFieldChangeset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridFieldChangeset clone() => GridFieldChangeset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridFieldChangeset copyWith(void Function(GridFieldChangeset) updates) => super.copyWith((message) => updates(message as GridFieldChangeset)) as GridFieldChangeset; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridFieldChangeset create() => GridFieldChangeset._();
  GridFieldChangeset createEmptyInstance() => create();
  static $pb.PbList<GridFieldChangeset> createRepeated() => $pb.PbList<GridFieldChangeset>();
  @$core.pragma('dart2js:noInline')
  static GridFieldChangeset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridFieldChangeset>(create);
  static GridFieldChangeset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<IndexField> get insertedFields => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<FieldOrder> get deletedFields => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<Field> get updatedFields => $_getList(3);
}

class IndexField extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'IndexField', createEmptyInstance: create)
    ..aOM<Field>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'field', subBuilder: Field.create)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  IndexField._() : super();
  factory IndexField({
    Field? field_1,
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
  factory IndexField.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IndexField.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IndexField clone() => IndexField()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IndexField copyWith(void Function(IndexField) updates) => super.copyWith((message) => updates(message as IndexField)) as IndexField; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static IndexField create() => IndexField._();
  IndexField createEmptyInstance() => create();
  static $pb.PbList<IndexField> createRepeated() => $pb.PbList<IndexField>();
  @$core.pragma('dart2js:noInline')
  static IndexField getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexField>(create);
  static IndexField? _defaultInstance;

  @$pb.TagNumber(1)
  Field get field_1 => $_getN(0);
  @$pb.TagNumber(1)
  set field_1(Field v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => clearField(1);
  @$pb.TagNumber(1)
  Field ensureField_1() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

enum GetEditFieldContextPayload_OneOfFieldId {
  fieldId, 
  notSet
}

class GetEditFieldContextPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, GetEditFieldContextPayload_OneOfFieldId> _GetEditFieldContextPayload_OneOfFieldIdByTag = {
    2 : GetEditFieldContextPayload_OneOfFieldId.fieldId,
    0 : GetEditFieldContextPayload_OneOfFieldId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetEditFieldContextPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..hasRequiredFields = false
  ;

  GetEditFieldContextPayload._() : super();
  factory GetEditFieldContextPayload({
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
  factory GetEditFieldContextPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetEditFieldContextPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetEditFieldContextPayload clone() => GetEditFieldContextPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetEditFieldContextPayload copyWith(void Function(GetEditFieldContextPayload) updates) => super.copyWith((message) => updates(message as GetEditFieldContextPayload)) as GetEditFieldContextPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetEditFieldContextPayload create() => GetEditFieldContextPayload._();
  GetEditFieldContextPayload createEmptyInstance() => create();
  static $pb.PbList<GetEditFieldContextPayload> createRepeated() => $pb.PbList<GetEditFieldContextPayload>();
  @$core.pragma('dart2js:noInline')
  static GetEditFieldContextPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEditFieldContextPayload>(create);
  static GetEditFieldContextPayload? _defaultInstance;

  GetEditFieldContextPayload_OneOfFieldId whichOneOfFieldId() => _GetEditFieldContextPayload_OneOfFieldIdByTag[$_whichOneof(0)]!;
  void clearOneOfFieldId() => clearField($_whichOneof(0));

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

class EditFieldPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EditFieldPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createIfNotExist')
    ..hasRequiredFields = false
  ;

  EditFieldPayload._() : super();
  factory EditFieldPayload({
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
  factory EditFieldPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EditFieldPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EditFieldPayload clone() => EditFieldPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EditFieldPayload copyWith(void Function(EditFieldPayload) updates) => super.copyWith((message) => updates(message as EditFieldPayload)) as EditFieldPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EditFieldPayload create() => EditFieldPayload._();
  EditFieldPayload createEmptyInstance() => create();
  static $pb.PbList<EditFieldPayload> createRepeated() => $pb.PbList<EditFieldPayload>();
  @$core.pragma('dart2js:noInline')
  static EditFieldPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EditFieldPayload>(create);
  static EditFieldPayload? _defaultInstance;

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

class FieldTypeOptionContext extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldTypeOptionContext', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<Field>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridField', subBuilder: Field.create)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  FieldTypeOptionContext._() : super();
  factory FieldTypeOptionContext({
    $core.String? gridId,
    Field? gridField,
    $core.List<$core.int>? typeOptionData,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (gridField != null) {
      _result.gridField = gridField;
    }
    if (typeOptionData != null) {
      _result.typeOptionData = typeOptionData;
    }
    return _result;
  }
  factory FieldTypeOptionContext.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldTypeOptionContext.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldTypeOptionContext clone() => FieldTypeOptionContext()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldTypeOptionContext copyWith(void Function(FieldTypeOptionContext) updates) => super.copyWith((message) => updates(message as FieldTypeOptionContext)) as FieldTypeOptionContext; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldTypeOptionContext create() => FieldTypeOptionContext._();
  FieldTypeOptionContext createEmptyInstance() => create();
  static $pb.PbList<FieldTypeOptionContext> createRepeated() => $pb.PbList<FieldTypeOptionContext>();
  @$core.pragma('dart2js:noInline')
  static FieldTypeOptionContext getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldTypeOptionContext>(create);
  static FieldTypeOptionContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  Field get gridField => $_getN(1);
  @$pb.TagNumber(2)
  set gridField(Field v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridField() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridField() => clearField(2);
  @$pb.TagNumber(2)
  Field ensureGridField() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get typeOptionData => $_getN(2);
  @$pb.TagNumber(3)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTypeOptionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearTypeOptionData() => clearField(3);
}

class FieldTypeOptionData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldTypeOptionData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<Field>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'field', subBuilder: Field.create)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  FieldTypeOptionData._() : super();
  factory FieldTypeOptionData({
    $core.String? gridId,
    Field? field_2,
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
  factory FieldTypeOptionData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldTypeOptionData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldTypeOptionData clone() => FieldTypeOptionData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldTypeOptionData copyWith(void Function(FieldTypeOptionData) updates) => super.copyWith((message) => updates(message as FieldTypeOptionData)) as FieldTypeOptionData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldTypeOptionData create() => FieldTypeOptionData._();
  FieldTypeOptionData createEmptyInstance() => create();
  static $pb.PbList<FieldTypeOptionData> createRepeated() => $pb.PbList<FieldTypeOptionData>();
  @$core.pragma('dart2js:noInline')
  static FieldTypeOptionData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldTypeOptionData>(create);
  static FieldTypeOptionData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  Field get field_2 => $_getN(1);
  @$pb.TagNumber(2)
  set field_2(Field v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasField_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearField_2() => clearField(2);
  @$pb.TagNumber(2)
  Field ensureField_2() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get typeOptionData => $_getN(2);
  @$pb.TagNumber(3)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTypeOptionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearTypeOptionData() => clearField(3);
}

class RepeatedField extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedField', createEmptyInstance: create)
    ..pc<Field>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: Field.create)
    ..hasRequiredFields = false
  ;

  RepeatedField._() : super();
  factory RepeatedField({
    $core.Iterable<Field>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedField.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedField.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedField clone() => RepeatedField()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedField copyWith(void Function(RepeatedField) updates) => super.copyWith((message) => updates(message as RepeatedField)) as RepeatedField; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedField create() => RepeatedField._();
  RepeatedField createEmptyInstance() => create();
  static $pb.PbList<RepeatedField> createRepeated() => $pb.PbList<RepeatedField>();
  @$core.pragma('dart2js:noInline')
  static RepeatedField getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedField>(create);
  static RepeatedField? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Field> get items => $_getList(0);
}

class RepeatedFieldOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedFieldOrder', createEmptyInstance: create)
    ..pc<FieldOrder>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: FieldOrder.create)
    ..hasRequiredFields = false
  ;

  RepeatedFieldOrder._() : super();
  factory RepeatedFieldOrder({
    $core.Iterable<FieldOrder>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedFieldOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedFieldOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedFieldOrder clone() => RepeatedFieldOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedFieldOrder copyWith(void Function(RepeatedFieldOrder) updates) => super.copyWith((message) => updates(message as RepeatedFieldOrder)) as RepeatedFieldOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedFieldOrder create() => RepeatedFieldOrder._();
  RepeatedFieldOrder createEmptyInstance() => create();
  static $pb.PbList<RepeatedFieldOrder> createRepeated() => $pb.PbList<RepeatedFieldOrder>();
  @$core.pragma('dart2js:noInline')
  static RepeatedFieldOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedFieldOrder>(create);
  static RepeatedFieldOrder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FieldOrder> get items => $_getList(0);
}

enum InsertFieldPayload_OneOfStartFieldId {
  startFieldId, 
  notSet
}

class InsertFieldPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, InsertFieldPayload_OneOfStartFieldId> _InsertFieldPayload_OneOfStartFieldIdByTag = {
    4 : InsertFieldPayload_OneOfStartFieldId.startFieldId,
    0 : InsertFieldPayload_OneOfStartFieldId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InsertFieldPayload', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<Field>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'field', subBuilder: Field.create)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startFieldId')
    ..hasRequiredFields = false
  ;

  InsertFieldPayload._() : super();
  factory InsertFieldPayload({
    $core.String? gridId,
    Field? field_2,
    $core.List<$core.int>? typeOptionData,
    $core.String? startFieldId,
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
    if (startFieldId != null) {
      _result.startFieldId = startFieldId;
    }
    return _result;
  }
  factory InsertFieldPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InsertFieldPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InsertFieldPayload clone() => InsertFieldPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InsertFieldPayload copyWith(void Function(InsertFieldPayload) updates) => super.copyWith((message) => updates(message as InsertFieldPayload)) as InsertFieldPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InsertFieldPayload create() => InsertFieldPayload._();
  InsertFieldPayload createEmptyInstance() => create();
  static $pb.PbList<InsertFieldPayload> createRepeated() => $pb.PbList<InsertFieldPayload>();
  @$core.pragma('dart2js:noInline')
  static InsertFieldPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InsertFieldPayload>(create);
  static InsertFieldPayload? _defaultInstance;

  InsertFieldPayload_OneOfStartFieldId whichOneOfStartFieldId() => _InsertFieldPayload_OneOfStartFieldIdByTag[$_whichOneof(0)]!;
  void clearOneOfStartFieldId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  Field get field_2 => $_getN(1);
  @$pb.TagNumber(2)
  set field_2(Field v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasField_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearField_2() => clearField(2);
  @$pb.TagNumber(2)
  Field ensureField_2() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get typeOptionData => $_getN(2);
  @$pb.TagNumber(3)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTypeOptionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearTypeOptionData() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get startFieldId => $_getSZ(3);
  @$pb.TagNumber(4)
  set startFieldId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasStartFieldId() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartFieldId() => clearField(4);
}

class UpdateFieldTypeOptionPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateFieldTypeOptionPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  UpdateFieldTypeOptionPayload._() : super();
  factory UpdateFieldTypeOptionPayload({
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
  factory UpdateFieldTypeOptionPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateFieldTypeOptionPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateFieldTypeOptionPayload clone() => UpdateFieldTypeOptionPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateFieldTypeOptionPayload copyWith(void Function(UpdateFieldTypeOptionPayload) updates) => super.copyWith((message) => updates(message as UpdateFieldTypeOptionPayload)) as UpdateFieldTypeOptionPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateFieldTypeOptionPayload create() => UpdateFieldTypeOptionPayload._();
  UpdateFieldTypeOptionPayload createEmptyInstance() => create();
  static $pb.PbList<UpdateFieldTypeOptionPayload> createRepeated() => $pb.PbList<UpdateFieldTypeOptionPayload>();
  @$core.pragma('dart2js:noInline')
  static UpdateFieldTypeOptionPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateFieldTypeOptionPayload>(create);
  static UpdateFieldTypeOptionPayload? _defaultInstance;

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

class QueryFieldPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryFieldPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<RepeatedFieldOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldOrders', subBuilder: RepeatedFieldOrder.create)
    ..hasRequiredFields = false
  ;

  QueryFieldPayload._() : super();
  factory QueryFieldPayload({
    $core.String? gridId,
    RepeatedFieldOrder? fieldOrders,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldOrders != null) {
      _result.fieldOrders = fieldOrders;
    }
    return _result;
  }
  factory QueryFieldPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryFieldPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryFieldPayload clone() => QueryFieldPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryFieldPayload copyWith(void Function(QueryFieldPayload) updates) => super.copyWith((message) => updates(message as QueryFieldPayload)) as QueryFieldPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryFieldPayload create() => QueryFieldPayload._();
  QueryFieldPayload createEmptyInstance() => create();
  static $pb.PbList<QueryFieldPayload> createRepeated() => $pb.PbList<QueryFieldPayload>();
  @$core.pragma('dart2js:noInline')
  static QueryFieldPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryFieldPayload>(create);
  static QueryFieldPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  RepeatedFieldOrder get fieldOrders => $_getN(1);
  @$pb.TagNumber(2)
  set fieldOrders(RepeatedFieldOrder v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldOrders() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldOrders() => clearField(2);
  @$pb.TagNumber(2)
  RepeatedFieldOrder ensureFieldOrders() => $_ensure(1);
}

enum FieldChangesetPayload_OneOfName {
  name, 
  notSet
}

enum FieldChangesetPayload_OneOfDesc {
  desc, 
  notSet
}

enum FieldChangesetPayload_OneOfFieldType {
  fieldType, 
  notSet
}

enum FieldChangesetPayload_OneOfFrozen {
  frozen, 
  notSet
}

enum FieldChangesetPayload_OneOfVisibility {
  visibility, 
  notSet
}

enum FieldChangesetPayload_OneOfWidth {
  width, 
  notSet
}

enum FieldChangesetPayload_OneOfTypeOptionData {
  typeOptionData, 
  notSet
}

class FieldChangesetPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfName> _FieldChangesetPayload_OneOfNameByTag = {
    3 : FieldChangesetPayload_OneOfName.name,
    0 : FieldChangesetPayload_OneOfName.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfDesc> _FieldChangesetPayload_OneOfDescByTag = {
    4 : FieldChangesetPayload_OneOfDesc.desc,
    0 : FieldChangesetPayload_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfFieldType> _FieldChangesetPayload_OneOfFieldTypeByTag = {
    5 : FieldChangesetPayload_OneOfFieldType.fieldType,
    0 : FieldChangesetPayload_OneOfFieldType.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfFrozen> _FieldChangesetPayload_OneOfFrozenByTag = {
    6 : FieldChangesetPayload_OneOfFrozen.frozen,
    0 : FieldChangesetPayload_OneOfFrozen.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfVisibility> _FieldChangesetPayload_OneOfVisibilityByTag = {
    7 : FieldChangesetPayload_OneOfVisibility.visibility,
    0 : FieldChangesetPayload_OneOfVisibility.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfWidth> _FieldChangesetPayload_OneOfWidthByTag = {
    8 : FieldChangesetPayload_OneOfWidth.width,
    0 : FieldChangesetPayload_OneOfWidth.notSet
  };
  static const $core.Map<$core.int, FieldChangesetPayload_OneOfTypeOptionData> _FieldChangesetPayload_OneOfTypeOptionDataByTag = {
    9 : FieldChangesetPayload_OneOfTypeOptionData.typeOptionData,
    0 : FieldChangesetPayload_OneOfTypeOptionData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldChangesetPayload', createEmptyInstance: create)
    ..oo(0, [3])
    ..oo(1, [4])
    ..oo(2, [5])
    ..oo(3, [6])
    ..oo(4, [7])
    ..oo(5, [8])
    ..oo(6, [9])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<FieldType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..aOB(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..a<$core.int>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  FieldChangesetPayload._() : super();
  factory FieldChangesetPayload({
    $core.String? fieldId,
    $core.String? gridId,
    $core.String? name,
    $core.String? desc,
    FieldType? fieldType,
    $core.bool? frozen,
    $core.bool? visibility,
    $core.int? width,
    $core.List<$core.int>? typeOptionData,
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
    if (typeOptionData != null) {
      _result.typeOptionData = typeOptionData;
    }
    return _result;
  }
  factory FieldChangesetPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldChangesetPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldChangesetPayload clone() => FieldChangesetPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldChangesetPayload copyWith(void Function(FieldChangesetPayload) updates) => super.copyWith((message) => updates(message as FieldChangesetPayload)) as FieldChangesetPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldChangesetPayload create() => FieldChangesetPayload._();
  FieldChangesetPayload createEmptyInstance() => create();
  static $pb.PbList<FieldChangesetPayload> createRepeated() => $pb.PbList<FieldChangesetPayload>();
  @$core.pragma('dart2js:noInline')
  static FieldChangesetPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldChangesetPayload>(create);
  static FieldChangesetPayload? _defaultInstance;

  FieldChangesetPayload_OneOfName whichOneOfName() => _FieldChangesetPayload_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  FieldChangesetPayload_OneOfDesc whichOneOfDesc() => _FieldChangesetPayload_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  FieldChangesetPayload_OneOfFieldType whichOneOfFieldType() => _FieldChangesetPayload_OneOfFieldTypeByTag[$_whichOneof(2)]!;
  void clearOneOfFieldType() => clearField($_whichOneof(2));

  FieldChangesetPayload_OneOfFrozen whichOneOfFrozen() => _FieldChangesetPayload_OneOfFrozenByTag[$_whichOneof(3)]!;
  void clearOneOfFrozen() => clearField($_whichOneof(3));

  FieldChangesetPayload_OneOfVisibility whichOneOfVisibility() => _FieldChangesetPayload_OneOfVisibilityByTag[$_whichOneof(4)]!;
  void clearOneOfVisibility() => clearField($_whichOneof(4));

  FieldChangesetPayload_OneOfWidth whichOneOfWidth() => _FieldChangesetPayload_OneOfWidthByTag[$_whichOneof(5)]!;
  void clearOneOfWidth() => clearField($_whichOneof(5));

  FieldChangesetPayload_OneOfTypeOptionData whichOneOfTypeOptionData() => _FieldChangesetPayload_OneOfTypeOptionDataByTag[$_whichOneof(6)]!;
  void clearOneOfTypeOptionData() => clearField($_whichOneof(6));

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

  @$pb.TagNumber(9)
  $core.List<$core.int> get typeOptionData => $_getN(8);
  @$pb.TagNumber(9)
  set typeOptionData($core.List<$core.int> v) { $_setBytes(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasTypeOptionData() => $_has(8);
  @$pb.TagNumber(9)
  void clearTypeOptionData() => clearField(9);
}

