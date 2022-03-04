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
    ..aOM<RepeatedFieldOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldOrders', subBuilder: RepeatedFieldOrder.create)
    ..aOM<RepeatedRowOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrders', subBuilder: RepeatedRowOrder.create)
    ..hasRequiredFields = false
  ;

  Grid._() : super();
  factory Grid({
    $core.String? id,
    RepeatedFieldOrder? fieldOrders,
    RepeatedRowOrder? rowOrders,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fieldOrders != null) {
      _result.fieldOrders = fieldOrders;
    }
    if (rowOrders != null) {
      _result.rowOrders = rowOrders;
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
  RepeatedFieldOrder get fieldOrders => $_getN(1);
  @$pb.TagNumber(2)
  set fieldOrders(RepeatedFieldOrder v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldOrders() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldOrders() => clearField(2);
  @$pb.TagNumber(2)
  RepeatedFieldOrder ensureFieldOrders() => $_ensure(1);

  @$pb.TagNumber(3)
  RepeatedRowOrder get rowOrders => $_getN(2);
  @$pb.TagNumber(3)
  set rowOrders(RepeatedRowOrder v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasRowOrders() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowOrders() => clearField(3);
  @$pb.TagNumber(3)
  RepeatedRowOrder ensureRowOrders() => $_ensure(2);
}

class FieldOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldOrder', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..hasRequiredFields = false
  ;

  FieldOrder._() : super();
  factory FieldOrder({
    $core.String? fieldId,
    $core.bool? visibility,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (visibility != null) {
      _result.visibility = visibility;
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

  @$pb.TagNumber(2)
  $core.bool get visibility => $_getBF(1);
  @$pb.TagNumber(2)
  set visibility($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVisibility() => $_has(1);
  @$pb.TagNumber(2)
  void clearVisibility() => clearField(2);
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

class Field extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Field', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<FieldType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..a<$core.int>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..aOM<AnyData>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptions', subBuilder: AnyData.create)
    ..hasRequiredFields = false
  ;

  Field._() : super();
  factory Field({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    FieldType? fieldType,
    $core.bool? frozen,
    $core.int? width,
    AnyData? typeOptions,
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
    if (width != null) {
      _result.width = width;
    }
    if (typeOptions != null) {
      _result.typeOptions = typeOptions;
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
  $core.int get width => $_getIZ(5);
  @$pb.TagNumber(6)
  set width($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasWidth() => $_has(5);
  @$pb.TagNumber(6)
  void clearWidth() => clearField(6);

  @$pb.TagNumber(7)
  AnyData get typeOptions => $_getN(6);
  @$pb.TagNumber(7)
  set typeOptions(AnyData v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasTypeOptions() => $_has(6);
  @$pb.TagNumber(7)
  void clearTypeOptions() => clearField(7);
  @$pb.TagNumber(7)
  AnyData ensureTypeOptions() => $_ensure(6);
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

class AnyData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AnyData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeId')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  AnyData._() : super();
  factory AnyData({
    $core.String? typeId,
    $core.List<$core.int>? value,
  }) {
    final _result = create();
    if (typeId != null) {
      _result.typeId = typeId;
    }
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory AnyData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AnyData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AnyData clone() => AnyData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AnyData copyWith(void Function(AnyData) updates) => super.copyWith((message) => updates(message as AnyData)) as AnyData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AnyData create() => AnyData._();
  AnyData createEmptyInstance() => create();
  static $pb.PbList<AnyData> createRepeated() => $pb.PbList<AnyData>();
  @$core.pragma('dart2js:noInline')
  static AnyData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AnyData>(create);
  static AnyData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get typeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set typeId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTypeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTypeId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

class RowOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowOrder', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..hasRequiredFields = false
  ;

  RowOrder._() : super();
  factory RowOrder({
    $core.String? gridId,
    $core.String? rowId,
    $core.bool? visibility,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (visibility != null) {
      _result.visibility = visibility;
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
  $core.bool get visibility => $_getBF(2);
  @$pb.TagNumber(3)
  set visibility($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearVisibility() => clearField(3);
}

class RepeatedRowOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedRowOrder', createEmptyInstance: create)
    ..pc<RowOrder>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..hasRequiredFields = false
  ;

  RepeatedRowOrder._() : super();
  factory RepeatedRowOrder({
    $core.Iterable<RowOrder>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedRowOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedRowOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedRowOrder clone() => RepeatedRowOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedRowOrder copyWith(void Function(RepeatedRowOrder) updates) => super.copyWith((message) => updates(message as RepeatedRowOrder)) as RepeatedRowOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedRowOrder create() => RepeatedRowOrder._();
  RepeatedRowOrder createEmptyInstance() => create();
  static $pb.PbList<RepeatedRowOrder> createRepeated() => $pb.PbList<RepeatedRowOrder>();
  @$core.pragma('dart2js:noInline')
  static RepeatedRowOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedRowOrder>(create);
  static RepeatedRowOrder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<RowOrder> get items => $_getList(0);
}

class RawRow extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RawRow', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..m<$core.String, RawCell>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellByFieldId', entryClassName: 'RawRow.CellByFieldIdEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: RawCell.create)
    ..hasRequiredFields = false
  ;

  RawRow._() : super();
  factory RawRow({
    $core.String? id,
    $core.String? gridId,
    $core.Map<$core.String, RawCell>? cellByFieldId,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (cellByFieldId != null) {
      _result.cellByFieldId.addAll(cellByFieldId);
    }
    return _result;
  }
  factory RawRow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RawRow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RawRow clone() => RawRow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RawRow copyWith(void Function(RawRow) updates) => super.copyWith((message) => updates(message as RawRow)) as RawRow; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RawRow create() => RawRow._();
  RawRow createEmptyInstance() => create();
  static $pb.PbList<RawRow> createRepeated() => $pb.PbList<RawRow>();
  @$core.pragma('dart2js:noInline')
  static RawRow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RawRow>(create);
  static RawRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get gridId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gridId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridId() => clearField(2);

  @$pb.TagNumber(3)
  $core.Map<$core.String, RawCell> get cellByFieldId => $_getMap(2);
}

class RawCell extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RawCell', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  RawCell._() : super();
  factory RawCell({
    $core.String? id,
    $core.String? rowId,
    $core.String? fieldId,
    $core.String? data,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
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
  factory RawCell.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RawCell.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RawCell clone() => RawCell()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RawCell copyWith(void Function(RawCell) updates) => super.copyWith((message) => updates(message as RawCell)) as RawCell; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RawCell create() => RawCell._();
  RawCell createEmptyInstance() => create();
  static $pb.PbList<RawCell> createRepeated() => $pb.PbList<RawCell>();
  @$core.pragma('dart2js:noInline')
  static RawCell getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RawCell>(create);
  static RawCell? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

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

class Row extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Row', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..m<$core.String, Cell>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellByFieldId', entryClassName: 'Row.CellByFieldIdEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: Cell.create)
    ..hasRequiredFields = false
  ;

  Row._() : super();
  factory Row({
    $core.String? id,
    $core.Map<$core.String, Cell>? cellByFieldId,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (cellByFieldId != null) {
      _result.cellByFieldId.addAll(cellByFieldId);
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
}

class Cell extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Cell', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..hasRequiredFields = false
  ;

  Cell._() : super();
  factory Cell({
    $core.String? id,
    $core.String? fieldId,
    $core.String? content,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
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

  @$pb.TagNumber(3)
  $core.String get content => $_getSZ(2);
  @$pb.TagNumber(3)
  set content($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => clearField(3);
}

class CellChangeset extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellChangeset', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  CellChangeset._() : super();
  factory CellChangeset({
    $core.String? id,
    $core.String? rowId,
    $core.String? fieldId,
    $core.String? data,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
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

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

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

