///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field.pb.dart' as $0;

import 'grid.pbenum.dart';

export 'grid.pbenum.dart';

class Grid extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Grid', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..pc<$0.FieldOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldOrders', $pb.PbFieldType.PM, subBuilder: $0.FieldOrder.create)
    ..pc<GridBlockOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockOrders', $pb.PbFieldType.PM, subBuilder: GridBlockOrder.create)
    ..hasRequiredFields = false
  ;

  Grid._() : super();
  factory Grid({
    $core.String? id,
    $core.Iterable<$0.FieldOrder>? fieldOrders,
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
  $core.List<$0.FieldOrder> get fieldOrders => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<GridBlockOrder> get blockOrders => $_getList(2);
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

class UpdatedRowOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdatedRowOrder', createEmptyInstance: create)
    ..aOM<RowOrder>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrder', subBuilder: RowOrder.create)
    ..aOM<Row>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'row', subBuilder: Row.create)
    ..hasRequiredFields = false
  ;

  UpdatedRowOrder._() : super();
  factory UpdatedRowOrder({
    RowOrder? rowOrder,
    Row? row,
  }) {
    final _result = create();
    if (rowOrder != null) {
      _result.rowOrder = rowOrder;
    }
    if (row != null) {
      _result.row = row;
    }
    return _result;
  }
  factory UpdatedRowOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdatedRowOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdatedRowOrder clone() => UpdatedRowOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdatedRowOrder copyWith(void Function(UpdatedRowOrder) updates) => super.copyWith((message) => updates(message as UpdatedRowOrder)) as UpdatedRowOrder; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdatedRowOrder create() => UpdatedRowOrder._();
  UpdatedRowOrder createEmptyInstance() => create();
  static $pb.PbList<UpdatedRowOrder> createRepeated() => $pb.PbList<UpdatedRowOrder>();
  @$core.pragma('dart2js:noInline')
  static UpdatedRowOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdatedRowOrder>(create);
  static UpdatedRowOrder? _defaultInstance;

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
  Row get row => $_getN(1);
  @$pb.TagNumber(2)
  set row(Row v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRow() => $_has(1);
  @$pb.TagNumber(2)
  void clearRow() => clearField(2);
  @$pb.TagNumber(2)
  Row ensureRow() => $_ensure(1);
}

class GridRowsChangeset extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridRowsChangeset', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..pc<IndexRowOrder>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedRows', $pb.PbFieldType.PM, subBuilder: IndexRowOrder.create)
    ..pc<RowOrder>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedRows', $pb.PbFieldType.PM, subBuilder: RowOrder.create)
    ..pc<UpdatedRowOrder>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedRows', $pb.PbFieldType.PM, subBuilder: UpdatedRowOrder.create)
    ..hasRequiredFields = false
  ;

  GridRowsChangeset._() : super();
  factory GridRowsChangeset({
    $core.String? blockId,
    $core.Iterable<IndexRowOrder>? insertedRows,
    $core.Iterable<RowOrder>? deletedRows,
    $core.Iterable<UpdatedRowOrder>? updatedRows,
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
  $core.List<UpdatedRowOrder> get updatedRows => $_getList(3);
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
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Cell._() : super();
  factory Cell({
    $core.String? fieldId,
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (data != null) {
      _result.data = data;
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
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
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

enum CellChangeset_OneOfCellContentChangeset {
  cellContentChangeset, 
  notSet
}

class CellChangeset extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CellChangeset_OneOfCellContentChangeset> _CellChangeset_OneOfCellContentChangesetByTag = {
    4 : CellChangeset_OneOfCellContentChangeset.cellContentChangeset,
    0 : CellChangeset_OneOfCellContentChangeset.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellChangeset', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellContentChangeset')
    ..hasRequiredFields = false
  ;

  CellChangeset._() : super();
  factory CellChangeset({
    $core.String? gridId,
    $core.String? rowId,
    $core.String? fieldId,
    $core.String? cellContentChangeset,
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
    if (cellContentChangeset != null) {
      _result.cellContentChangeset = cellContentChangeset;
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

  CellChangeset_OneOfCellContentChangeset whichOneOfCellContentChangeset() => _CellChangeset_OneOfCellContentChangesetByTag[$_whichOneof(0)]!;
  void clearOneOfCellContentChangeset() => clearField($_whichOneof(0));

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
  $core.String get cellContentChangeset => $_getSZ(3);
  @$pb.TagNumber(4)
  set cellContentChangeset($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCellContentChangeset() => $_has(3);
  @$pb.TagNumber(4)
  void clearCellContentChangeset() => clearField(4);
}

