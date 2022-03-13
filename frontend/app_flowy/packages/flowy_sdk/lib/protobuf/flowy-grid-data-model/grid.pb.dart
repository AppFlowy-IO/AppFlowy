///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Grid extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Grid', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..pc<FieldOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldOrders', $pb.PbFieldType.PM, subBuilder: FieldOrder.create)
    ..pc<RowOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrders', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..hasRequiredFields = false
  ;

  Grid._() : super();
  factory Grid({
    $core.String? id,
    $core.Iterable<FieldOrder>? fieldOrders,
    $core.Iterable<RowOrder>? rowOrders,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fieldOrders != null) {
      _result.fieldOrders.addAll(fieldOrders);
    }
    if (rowOrders != null) {
      _result.rowOrders.addAll(rowOrders);
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
  $core.List<RowOrder> get rowOrders => $_getList(2);
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

class QueryRowPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryRowPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<RepeatedRowOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrders', subBuilder: RepeatedRowOrder.create)
    ..hasRequiredFields = false
  ;

  QueryRowPayload._() : super();
  factory QueryRowPayload({
    $core.String? gridId,
    RepeatedRowOrder? rowOrders,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (rowOrders != null) {
      _result.rowOrders = rowOrders;
    }
    return _result;
  }
  factory QueryRowPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryRowPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryRowPayload clone() => QueryRowPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryRowPayload copyWith(void Function(QueryRowPayload) updates) => super.copyWith((message) => updates(message as QueryRowPayload)) as QueryRowPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryRowPayload create() => QueryRowPayload._();
  QueryRowPayload createEmptyInstance() => create();
  static $pb.PbList<QueryRowPayload> createRepeated() => $pb.PbList<QueryRowPayload>();
  @$core.pragma('dart2js:noInline')
  static QueryRowPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryRowPayload>(create);
  static QueryRowPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  RepeatedRowOrder get rowOrders => $_getN(1);
  @$pb.TagNumber(2)
  set rowOrders(RepeatedRowOrder v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRowOrders() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowOrders() => clearField(2);
  @$pb.TagNumber(2)
  RepeatedRowOrder ensureRowOrders() => $_ensure(1);
}

