///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'grid.pbenum.dart';

export 'grid.pbenum.dart';

class Grid extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Grid', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..pc<FieldOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldOrders', $pb.PbFieldType.PM, subBuilder: FieldOrder.create)
    ..pc<GridBlockOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockOrders', $pb.PbFieldType.PM, subBuilder: GridBlockOrder.create)
    ..hasRequiredFields = false
  ;

  Grid._() : super();
  factory Grid({
    $core.String? id,
    $core.Iterable<FieldOrder>? fieldOrders,
    $core.Iterable<GridBlockOrder>? blockOrders,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fieldOrders != null) {
      _result.fieldOrders.addAll(fieldOrders);
    }
    if (blockOrders != null) {
      _result.blockOrders.addAll(blockOrders);
    }
    return _result;
  }
  factory Grid.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Grid.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Grid clone() => Grid()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Grid copyWith(void Function(Grid) updates) => super.copyWith((message) => updates(message as Grid)) as Grid; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Grid create() => Grid._();
  Grid createEmptyInstance() => create();
  static $pb.PbList<Grid> createRepeated() => $pb.PbList<Grid>();
  @$core.pragma('dart2js:noInline')
  static Grid getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Grid>(create);
  static Grid? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<FieldOrder> get fieldOrders => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<GridBlockOrder> get blockOrders => $_getList(2);
}

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
    ..hasRequiredFields = false
  ;

  EditFieldPayload._() : super();
  factory EditFieldPayload({
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
}

class EditFieldContext extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EditFieldContext', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<Field>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridField', subBuilder: Field.create)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  EditFieldContext._() : super();
  factory EditFieldContext({
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
  factory EditFieldContext.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EditFieldContext.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EditFieldContext clone() => EditFieldContext()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EditFieldContext copyWith(void Function(EditFieldContext) updates) => super.copyWith((message) => updates(message as EditFieldContext)) as EditFieldContext; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EditFieldContext create() => EditFieldContext._();
  EditFieldContext createEmptyInstance() => create();
  static $pb.PbList<EditFieldContext> createRepeated() => $pb.PbList<EditFieldContext>();
  @$core.pragma('dart2js:noInline')
  static EditFieldContext getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EditFieldContext>(create);
  static EditFieldContext? _defaultInstance;

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

class RowOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowOrder', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  RowOrder._() : super();
  factory RowOrder({
    $core.String? rowId,
    $core.String? blockId,
    $core.int? height,
  }) {
    final _result = create();
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (height != null) {
      _result.height = height;
    }
    return _result;
  }
  factory RowOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RowOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RowOrder clone() => RowOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RowOrder copyWith(void Function(RowOrder) updates) => super.copyWith((message) => updates(message as RowOrder)) as RowOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RowOrder create() => RowOrder._();
  RowOrder createEmptyInstance() => create();
  static $pb.PbList<RowOrder> createRepeated() => $pb.PbList<RowOrder>();
  @$core.pragma('dart2js:noInline')
  static RowOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowOrder>(create);
  static RowOrder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get rowId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rowId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRowId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRowId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get blockId => $_getSZ(1);
  @$pb.TagNumber(2)
  set blockId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBlockId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlockId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);
}

class Row extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Row', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..m<$core.String, Cell>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellByFieldId', entryClassName: 'Row.CellByFieldIdEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: Cell.create)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  Row._() : super();
  factory Row({
    $core.String? id,
    $core.Map<$core.String, Cell>? cellByFieldId,
    $core.int? height,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (cellByFieldId != null) {
      _result.cellByFieldId.addAll(cellByFieldId);
    }
    if (height != null) {
      _result.height = height;
    }
    return _result;
  }
  factory Row.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Row.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Row clone() => Row()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Row copyWith(void Function(Row) updates) => super.copyWith((message) => updates(message as Row)) as Row; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Row create() => Row._();
  Row createEmptyInstance() => create();
  static $pb.PbList<Row> createRepeated() => $pb.PbList<Row>();
  @$core.pragma('dart2js:noInline')
  static Row getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Row>(create);
  static Row? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.Map<$core.String, Cell> get cellByFieldId => $_getMap(1);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);
}

class RepeatedRow extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedRow', createEmptyInstance: create)
    ..pc<Row>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: Row.create)
    ..hasRequiredFields = false
  ;

  RepeatedRow._() : super();
  factory RepeatedRow({
    $core.Iterable<Row>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedRow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedRow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedRow clone() => RepeatedRow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedRow copyWith(void Function(RepeatedRow) updates) => super.copyWith((message) => updates(message as RepeatedRow)) as RepeatedRow; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedRow create() => RepeatedRow._();
  RepeatedRow createEmptyInstance() => create();
  static $pb.PbList<RepeatedRow> createRepeated() => $pb.PbList<RepeatedRow>();
  @$core.pragma('dart2js:noInline')
  static RepeatedRow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedRow>(create);
  static RepeatedRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Row> get items => $_getList(0);
}

class RepeatedGridBlock extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedGridBlock', createEmptyInstance: create)
    ..pc<GridBlock>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: GridBlock.create)
    ..hasRequiredFields = false
  ;

  RepeatedGridBlock._() : super();
  factory RepeatedGridBlock({
    $core.Iterable<GridBlock>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedGridBlock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedGridBlock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedGridBlock clone() => RepeatedGridBlock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedGridBlock copyWith(void Function(RepeatedGridBlock) updates) => super.copyWith((message) => updates(message as RepeatedGridBlock)) as RepeatedGridBlock; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedGridBlock create() => RepeatedGridBlock._();
  RepeatedGridBlock createEmptyInstance() => create();
  static $pb.PbList<RepeatedGridBlock> createRepeated() => $pb.PbList<RepeatedGridBlock>();
  @$core.pragma('dart2js:noInline')
  static RepeatedGridBlock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedGridBlock>(create);
  static RepeatedGridBlock? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GridBlock> get items => $_getList(0);
}

class GridBlockOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlockOrder', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..pc<RowOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrders', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..hasRequiredFields = false
  ;

  GridBlockOrder._() : super();
  factory GridBlockOrder({
    $core.String? blockId,
    $core.Iterable<RowOrder>? rowOrders,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (rowOrders != null) {
      _result.rowOrders.addAll(rowOrders);
    }
    return _result;
  }
  factory GridBlockOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridBlockOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridBlockOrder clone() => GridBlockOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridBlockOrder copyWith(void Function(GridBlockOrder) updates) => super.copyWith((message) => updates(message as GridBlockOrder)) as GridBlockOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridBlockOrder create() => GridBlockOrder._();
  GridBlockOrder createEmptyInstance() => create();
  static $pb.PbList<GridBlockOrder> createRepeated() => $pb.PbList<GridBlockOrder>();
  @$core.pragma('dart2js:noInline')
  static GridBlockOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridBlockOrder>(create);
  static GridBlockOrder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<RowOrder> get rowOrders => $_getList(1);
}

enum IndexRowOrder_OneOfIndex {
  index_, 
  notSet
}

class IndexRowOrder extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, IndexRowOrder_OneOfIndex> _IndexRowOrder_OneOfIndexByTag = {
    2 : IndexRowOrder_OneOfIndex.index_,
    0 : IndexRowOrder_OneOfIndex.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'IndexRowOrder', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOM<RowOrder>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrder', subBuilder: RowOrder.create)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  IndexRowOrder._() : super();
  factory IndexRowOrder({
    RowOrder? rowOrder,
    $core.int? index,
  }) {
    final _result = create();
    if (rowOrder != null) {
      _result.rowOrder = rowOrder;
    }
    if (index != null) {
      _result.index = index;
    }
    return _result;
  }
  factory IndexRowOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IndexRowOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IndexRowOrder clone() => IndexRowOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IndexRowOrder copyWith(void Function(IndexRowOrder) updates) => super.copyWith((message) => updates(message as IndexRowOrder)) as IndexRowOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static IndexRowOrder create() => IndexRowOrder._();
  IndexRowOrder createEmptyInstance() => create();
  static $pb.PbList<IndexRowOrder> createRepeated() => $pb.PbList<IndexRowOrder>();
  @$core.pragma('dart2js:noInline')
  static IndexRowOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexRowOrder>(create);
  static IndexRowOrder? _defaultInstance;

  IndexRowOrder_OneOfIndex whichOneOfIndex() => _IndexRowOrder_OneOfIndexByTag[$_whichOneof(0)]!;
  void clearOneOfIndex() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  RowOrder get rowOrder => $_getN(0);
  @$pb.TagNumber(1)
  set rowOrder(RowOrder v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRowOrder() => $_has(0);
  @$pb.TagNumber(1)
  void clearRowOrder() => clearField(1);
  @$pb.TagNumber(1)
  RowOrder ensureRowOrder() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

class GridRowsChangeset extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridRowsChangeset', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..pc<IndexRowOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedRows', $pb.PbFieldType.PM, subBuilder: IndexRowOrder.create)
    ..pc<RowOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedRows', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..pc<RowOrder>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedRows', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..hasRequiredFields = false
  ;

  GridRowsChangeset._() : super();
  factory GridRowsChangeset({
    $core.String? blockId,
    $core.Iterable<IndexRowOrder>? insertedRows,
    $core.Iterable<RowOrder>? deletedRows,
    $core.Iterable<RowOrder>? updatedRows,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
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
  factory GridRowsChangeset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridRowsChangeset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridRowsChangeset clone() => GridRowsChangeset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridRowsChangeset copyWith(void Function(GridRowsChangeset) updates) => super.copyWith((message) => updates(message as GridRowsChangeset)) as GridRowsChangeset; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridRowsChangeset create() => GridRowsChangeset._();
  GridRowsChangeset createEmptyInstance() => create();
  static $pb.PbList<GridRowsChangeset> createRepeated() => $pb.PbList<GridRowsChangeset>();
  @$core.pragma('dart2js:noInline')
  static GridRowsChangeset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridRowsChangeset>(create);
  static GridRowsChangeset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<IndexRowOrder> get insertedRows => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<RowOrder> get deletedRows => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<RowOrder> get updatedRows => $_getList(3);
}

class GridBlock extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlock', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..pc<RowOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrders', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..hasRequiredFields = false
  ;

  GridBlock._() : super();
  factory GridBlock({
    $core.String? id,
    $core.Iterable<RowOrder>? rowOrders,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (rowOrders != null) {
      _result.rowOrders.addAll(rowOrders);
    }
    return _result;
  }
  factory GridBlock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridBlock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridBlock clone() => GridBlock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridBlock copyWith(void Function(GridBlock) updates) => super.copyWith((message) => updates(message as GridBlock)) as GridBlock; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridBlock create() => GridBlock._();
  GridBlock createEmptyInstance() => create();
  static $pb.PbList<GridBlock> createRepeated() => $pb.PbList<GridBlock>();
  @$core.pragma('dart2js:noInline')
  static GridBlock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridBlock>(create);
  static GridBlock? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<RowOrder> get rowOrders => $_getList(1);
}

class Cell extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Cell', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..hasRequiredFields = false
  ;

  Cell._() : super();
  factory Cell({
    $core.String? fieldId,
    $core.String? content,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (content != null) {
      _result.content = content;
    }
    return _result;
  }
  factory Cell.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Cell.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Cell clone() => Cell()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Cell copyWith(void Function(Cell) updates) => super.copyWith((message) => updates(message as Cell)) as Cell; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Cell create() => Cell._();
  Cell createEmptyInstance() => create();
  static $pb.PbList<Cell> createRepeated() => $pb.PbList<Cell>();
  @$core.pragma('dart2js:noInline')
  static Cell getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Cell>(create);
  static Cell? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => clearField(2);
}

enum CellNotificationData_OneOfContent {
  content, 
  notSet
}

class CellNotificationData extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CellNotificationData_OneOfContent> _CellNotificationData_OneOfContentByTag = {
    4 : CellNotificationData_OneOfContent.content,
    0 : CellNotificationData_OneOfContent.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellNotificationData', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..hasRequiredFields = false
  ;

  CellNotificationData._() : super();
  factory CellNotificationData({
    $core.String? gridId,
    $core.String? fieldId,
    $core.String? rowId,
    $core.String? content,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (content != null) {
      _result.content = content;
    }
    return _result;
  }
  factory CellNotificationData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellNotificationData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellNotificationData clone() => CellNotificationData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellNotificationData copyWith(void Function(CellNotificationData) updates) => super.copyWith((message) => updates(message as CellNotificationData)) as CellNotificationData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellNotificationData create() => CellNotificationData._();
  CellNotificationData createEmptyInstance() => create();
  static $pb.PbList<CellNotificationData> createRepeated() => $pb.PbList<CellNotificationData>();
  @$core.pragma('dart2js:noInline')
  static CellNotificationData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellNotificationData>(create);
  static CellNotificationData? _defaultInstance;

  CellNotificationData_OneOfContent whichOneOfContent() => _CellNotificationData_OneOfContentByTag[$_whichOneof(0)]!;
  void clearOneOfContent() => clearField($_whichOneof(0));

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
  $core.String get rowId => $_getSZ(2);
  @$pb.TagNumber(3)
  set rowId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRowId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get content => $_getSZ(3);
  @$pb.TagNumber(4)
  set content($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearContent() => clearField(4);
}

class RepeatedCell extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedCell', createEmptyInstance: create)
    ..pc<Cell>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: Cell.create)
    ..hasRequiredFields = false
  ;

  RepeatedCell._() : super();
  factory RepeatedCell({
    $core.Iterable<Cell>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedCell.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedCell.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedCell clone() => RepeatedCell()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedCell copyWith(void Function(RepeatedCell) updates) => super.copyWith((message) => updates(message as RepeatedCell)) as RepeatedCell; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedCell create() => RepeatedCell._();
  RepeatedCell createEmptyInstance() => create();
  static $pb.PbList<RepeatedCell> createRepeated() => $pb.PbList<RepeatedCell>();
  @$core.pragma('dart2js:noInline')
  static RepeatedCell getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedCell>(create);
  static RepeatedCell? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Cell> get items => $_getList(0);
}

class CreateGridPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateGridPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..hasRequiredFields = false
  ;

  CreateGridPayload._() : super();
  factory CreateGridPayload({
    $core.String? name,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    return _result;
  }
  factory CreateGridPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateGridPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateGridPayload clone() => CreateGridPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateGridPayload copyWith(void Function(CreateGridPayload) updates) => super.copyWith((message) => updates(message as CreateGridPayload)) as CreateGridPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateGridPayload create() => CreateGridPayload._();
  CreateGridPayload createEmptyInstance() => create();
  static $pb.PbList<CreateGridPayload> createRepeated() => $pb.PbList<CreateGridPayload>();
  @$core.pragma('dart2js:noInline')
  static CreateGridPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateGridPayload>(create);
  static CreateGridPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);
}

class GridId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  GridId._() : super();
  factory GridId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory GridId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridId clone() => GridId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridId copyWith(void Function(GridId) updates) => super.copyWith((message) => updates(message as GridId)) as GridId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridId create() => GridId._();
  GridId createEmptyInstance() => create();
  static $pb.PbList<GridId> createRepeated() => $pb.PbList<GridId>();
  @$core.pragma('dart2js:noInline')
  static GridId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridId>(create);
  static GridId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class GridBlockId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlockId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  GridBlockId._() : super();
  factory GridBlockId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory GridBlockId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridBlockId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridBlockId clone() => GridBlockId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridBlockId copyWith(void Function(GridBlockId) updates) => super.copyWith((message) => updates(message as GridBlockId)) as GridBlockId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridBlockId create() => GridBlockId._();
  GridBlockId createEmptyInstance() => create();
  static $pb.PbList<GridBlockId> createRepeated() => $pb.PbList<GridBlockId>();
  @$core.pragma('dart2js:noInline')
  static GridBlockId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridBlockId>(create);
  static GridBlockId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

enum CreateRowPayload_OneOfStartRowId {
  startRowId, 
  notSet
}

class CreateRowPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateRowPayload_OneOfStartRowId> _CreateRowPayload_OneOfStartRowIdByTag = {
    2 : CreateRowPayload_OneOfStartRowId.startRowId,
    0 : CreateRowPayload_OneOfStartRowId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateRowPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startRowId')
    ..hasRequiredFields = false
  ;

  CreateRowPayload._() : super();
  factory CreateRowPayload({
    $core.String? gridId,
    $core.String? startRowId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (startRowId != null) {
      _result.startRowId = startRowId;
    }
    return _result;
  }
  factory CreateRowPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateRowPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateRowPayload clone() => CreateRowPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateRowPayload copyWith(void Function(CreateRowPayload) updates) => super.copyWith((message) => updates(message as CreateRowPayload)) as CreateRowPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateRowPayload create() => CreateRowPayload._();
  CreateRowPayload createEmptyInstance() => create();
  static $pb.PbList<CreateRowPayload> createRepeated() => $pb.PbList<CreateRowPayload>();
  @$core.pragma('dart2js:noInline')
  static CreateRowPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateRowPayload>(create);
  static CreateRowPayload? _defaultInstance;

  CreateRowPayload_OneOfStartRowId whichOneOfStartRowId() => _CreateRowPayload_OneOfStartRowIdByTag[$_whichOneof(0)]!;
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
  $core.String get startRowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set startRowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStartRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartRowId() => clearField(2);
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

class QueryGridBlocksPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryGridBlocksPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..pc<GridBlockOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockOrders', $pb.PbFieldType.PM, subBuilder: GridBlockOrder.create)
    ..hasRequiredFields = false
  ;

  QueryGridBlocksPayload._() : super();
  factory QueryGridBlocksPayload({
    $core.String? gridId,
    $core.Iterable<GridBlockOrder>? blockOrders,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (blockOrders != null) {
      _result.blockOrders.addAll(blockOrders);
    }
    return _result;
  }
  factory QueryGridBlocksPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryGridBlocksPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryGridBlocksPayload clone() => QueryGridBlocksPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryGridBlocksPayload copyWith(void Function(QueryGridBlocksPayload) updates) => super.copyWith((message) => updates(message as QueryGridBlocksPayload)) as QueryGridBlocksPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryGridBlocksPayload create() => QueryGridBlocksPayload._();
  QueryGridBlocksPayload createEmptyInstance() => create();
  static $pb.PbList<QueryGridBlocksPayload> createRepeated() => $pb.PbList<QueryGridBlocksPayload>();
  @$core.pragma('dart2js:noInline')
  static QueryGridBlocksPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryGridBlocksPayload>(create);
  static QueryGridBlocksPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<GridBlockOrder> get blockOrders => $_getList(1);
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

class MoveItemPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveItemPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'itemId')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toIndex', $pb.PbFieldType.O3)
    ..e<MoveItemType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: MoveItemType.MoveField, valueOf: MoveItemType.valueOf, enumValues: MoveItemType.values)
    ..hasRequiredFields = false
  ;

  MoveItemPayload._() : super();
  factory MoveItemPayload({
    $core.String? gridId,
    $core.String? itemId,
    $core.int? fromIndex,
    $core.int? toIndex,
    MoveItemType? ty,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (itemId != null) {
      _result.itemId = itemId;
    }
    if (fromIndex != null) {
      _result.fromIndex = fromIndex;
    }
    if (toIndex != null) {
      _result.toIndex = toIndex;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory MoveItemPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveItemPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveItemPayload clone() => MoveItemPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveItemPayload copyWith(void Function(MoveItemPayload) updates) => super.copyWith((message) => updates(message as MoveItemPayload)) as MoveItemPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveItemPayload create() => MoveItemPayload._();
  MoveItemPayload createEmptyInstance() => create();
  static $pb.PbList<MoveItemPayload> createRepeated() => $pb.PbList<MoveItemPayload>();
  @$core.pragma('dart2js:noInline')
  static MoveItemPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveItemPayload>(create);
  static MoveItemPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get itemId => $_getSZ(1);
  @$pb.TagNumber(2)
  set itemId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasItemId() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get fromIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set fromIndex($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFromIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromIndex() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get toIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set toIndex($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasToIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearToIndex() => clearField(4);

  @$pb.TagNumber(5)
  MoveItemType get ty => $_getN(4);
  @$pb.TagNumber(5)
  set ty(MoveItemType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTy() => $_has(4);
  @$pb.TagNumber(5)
  void clearTy() => clearField(5);
}

enum CellChangeset_OneOfData {
  data, 
  notSet
}

class CellChangeset extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CellChangeset_OneOfData> _CellChangeset_OneOfDataByTag = {
    4 : CellChangeset_OneOfData.data,
    0 : CellChangeset_OneOfData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellChangeset', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  CellChangeset._() : super();
  factory CellChangeset({
    $core.String? gridId,
    $core.String? rowId,
    $core.String? fieldId,
    $core.String? data,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory CellChangeset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellChangeset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellChangeset clone() => CellChangeset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellChangeset copyWith(void Function(CellChangeset) updates) => super.copyWith((message) => updates(message as CellChangeset)) as CellChangeset; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellChangeset create() => CellChangeset._();
  CellChangeset createEmptyInstance() => create();
  static $pb.PbList<CellChangeset> createRepeated() => $pb.PbList<CellChangeset>();
  @$core.pragma('dart2js:noInline')
  static CellChangeset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellChangeset>(create);
  static CellChangeset? _defaultInstance;

  CellChangeset_OneOfData whichOneOfData() => _CellChangeset_OneOfDataByTag[$_whichOneof(0)]!;
  void clearOneOfData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get rowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set rowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get fieldId => $_getSZ(2);
  @$pb.TagNumber(3)
  set fieldId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get data => $_getSZ(3);
  @$pb.TagNumber(4)
  set data($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => clearField(4);
}

