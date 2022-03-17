///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'meta.pb.dart' as $0;

import 'meta.pbenum.dart' as $0;

class Grid extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Grid', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..pc<FieldOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldOrders', $pb.PbFieldType.PM, subBuilder: FieldOrder.create)
    ..pc<$0.GridBlockMeta>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blocks', $pb.PbFieldType.PM, subBuilder: $0.GridBlockMeta.create)
    ..hasRequiredFields = false
  ;

  Grid._() : super();
  factory Grid({
    $core.String? id,
    $core.Iterable<FieldOrder>? fieldOrders,
    $core.Iterable<$0.GridBlockMeta>? blocks,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fieldOrders != null) {
      _result.fieldOrders.addAll(fieldOrders);
    }
    if (blocks != null) {
      _result.blocks.addAll(blocks);
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
  $core.List<$0.GridBlockMeta> get blocks => $_getList(2);
}

class Field extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Field', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<$0.FieldType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  Field._() : super();
  factory Field({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    $0.FieldType? fieldType,
    $core.bool? frozen,
    $core.bool? visibility,
    $core.int? width,
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
  $0.FieldType get fieldType => $_getN(3);
  @$pb.TagNumber(4)
  set fieldType($0.FieldType v) { setField(4, v); }
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
    ..hasRequiredFields = false
  ;

  RowOrder._() : super();
  factory RowOrder({
    $core.String? rowId,
    $core.String? blockId,
  }) {
    final _result = create();
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (blockId != null) {
      _result.blockId = blockId;
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

class GridBlock extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlock', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..pc<Row>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rows', $pb.PbFieldType.PM, subBuilder: Row.create)
    ..hasRequiredFields = false
  ;

  GridBlock._() : super();
  factory GridBlock({
    $core.String? blockId,
    $core.Iterable<Row>? rows,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (rows != null) {
      _result.rows.addAll(rows);
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
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Row> get rows => $_getList(1);
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

enum CreateRowPayload_OneOfUpperRowId {
  upperRowId, 
  notSet
}

class CreateRowPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateRowPayload_OneOfUpperRowId> _CreateRowPayload_OneOfUpperRowIdByTag = {
    2 : CreateRowPayload_OneOfUpperRowId.upperRowId,
    0 : CreateRowPayload_OneOfUpperRowId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateRowPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'upperRowId')
    ..hasRequiredFields = false
  ;

  CreateRowPayload._() : super();
  factory CreateRowPayload({
    $core.String? gridId,
    $core.String? upperRowId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (upperRowId != null) {
      _result.upperRowId = upperRowId;
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

  CreateRowPayload_OneOfUpperRowId whichOneOfUpperRowId() => _CreateRowPayload_OneOfUpperRowIdByTag[$_whichOneof(0)]!;
  void clearOneOfUpperRowId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get upperRowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set upperRowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUpperRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpperRowId() => clearField(2);
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
    ..pc<$0.GridBlockMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blocks', $pb.PbFieldType.PM, subBuilder: $0.GridBlockMeta.create)
    ..hasRequiredFields = false
  ;

  QueryGridBlocksPayload._() : super();
  factory QueryGridBlocksPayload({
    $core.String? gridId,
    $core.Iterable<$0.GridBlockMeta>? blocks,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (blocks != null) {
      _result.blocks.addAll(blocks);
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
  $core.List<$0.GridBlockMeta> get blocks => $_getList(1);
}

