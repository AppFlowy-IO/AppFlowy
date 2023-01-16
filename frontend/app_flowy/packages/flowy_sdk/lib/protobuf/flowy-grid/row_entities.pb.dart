///
//  Generated code. Do not modify.
//  source: row_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class RowPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  RowPB._() : super();
  factory RowPB({
    $core.String? blockId,
    $core.String? id,
    $core.int? height,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (id != null) {
      _result.id = id;
    }
    if (height != null) {
      _result.height = height;
    }
    return _result;
  }
  factory RowPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RowPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RowPB clone() => RowPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RowPB copyWith(void Function(RowPB) updates) => super.copyWith((message) => updates(message as RowPB)) as RowPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RowPB create() => RowPB._();
  RowPB createEmptyInstance() => create();
  static $pb.PbList<RowPB> createRepeated() => $pb.PbList<RowPB>();
  @$core.pragma('dart2js:noInline')
  static RowPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowPB>(create);
  static RowPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);
}

enum OptionalRowPB_OneOfRow {
  row, 
  notSet
}

class OptionalRowPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, OptionalRowPB_OneOfRow> _OptionalRowPB_OneOfRowByTag = {
    1 : OptionalRowPB_OneOfRow.row,
    0 : OptionalRowPB_OneOfRow.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OptionalRowPB', createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<RowPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'row', subBuilder: RowPB.create)
    ..hasRequiredFields = false
  ;

  OptionalRowPB._() : super();
  factory OptionalRowPB({
    RowPB? row,
  }) {
    final _result = create();
    if (row != null) {
      _result.row = row;
    }
    return _result;
  }
  factory OptionalRowPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OptionalRowPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OptionalRowPB clone() => OptionalRowPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OptionalRowPB copyWith(void Function(OptionalRowPB) updates) => super.copyWith((message) => updates(message as OptionalRowPB)) as OptionalRowPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OptionalRowPB create() => OptionalRowPB._();
  OptionalRowPB createEmptyInstance() => create();
  static $pb.PbList<OptionalRowPB> createRepeated() => $pb.PbList<OptionalRowPB>();
  @$core.pragma('dart2js:noInline')
  static OptionalRowPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OptionalRowPB>(create);
  static OptionalRowPB? _defaultInstance;

  OptionalRowPB_OneOfRow whichOneOfRow() => _OptionalRowPB_OneOfRowByTag[$_whichOneof(0)]!;
  void clearOneOfRow() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  RowPB get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(RowPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => clearField(1);
  @$pb.TagNumber(1)
  RowPB ensureRow() => $_ensure(0);
}

class RepeatedRowPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedRowPB', createEmptyInstance: create)
    ..pc<RowPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: RowPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedRowPB._() : super();
  factory RepeatedRowPB({
    $core.Iterable<RowPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedRowPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedRowPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedRowPB clone() => RepeatedRowPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedRowPB copyWith(void Function(RepeatedRowPB) updates) => super.copyWith((message) => updates(message as RepeatedRowPB)) as RepeatedRowPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedRowPB create() => RepeatedRowPB._();
  RepeatedRowPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedRowPB> createRepeated() => $pb.PbList<RepeatedRowPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedRowPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedRowPB>(create);
  static RepeatedRowPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<RowPB> get items => $_getList(0);
}

enum InsertedRowPB_OneOfIndex {
  index_, 
  notSet
}

class InsertedRowPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, InsertedRowPB_OneOfIndex> _InsertedRowPB_OneOfIndexByTag = {
    2 : InsertedRowPB_OneOfIndex.index_,
    0 : InsertedRowPB_OneOfIndex.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InsertedRowPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOM<RowPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'row', subBuilder: RowPB.create)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.O3)
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isNew')
    ..hasRequiredFields = false
  ;

  InsertedRowPB._() : super();
  factory InsertedRowPB({
    RowPB? row,
    $core.int? index,
    $core.bool? isNew,
  }) {
    final _result = create();
    if (row != null) {
      _result.row = row;
    }
    if (index != null) {
      _result.index = index;
    }
    if (isNew != null) {
      _result.isNew = isNew;
    }
    return _result;
  }
  factory InsertedRowPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InsertedRowPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InsertedRowPB clone() => InsertedRowPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InsertedRowPB copyWith(void Function(InsertedRowPB) updates) => super.copyWith((message) => updates(message as InsertedRowPB)) as InsertedRowPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InsertedRowPB create() => InsertedRowPB._();
  InsertedRowPB createEmptyInstance() => create();
  static $pb.PbList<InsertedRowPB> createRepeated() => $pb.PbList<InsertedRowPB>();
  @$core.pragma('dart2js:noInline')
  static InsertedRowPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InsertedRowPB>(create);
  static InsertedRowPB? _defaultInstance;

  InsertedRowPB_OneOfIndex whichOneOfIndex() => _InsertedRowPB_OneOfIndexByTag[$_whichOneof(0)]!;
  void clearOneOfIndex() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  RowPB get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(RowPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => clearField(1);
  @$pb.TagNumber(1)
  RowPB ensureRow() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isNew => $_getBF(2);
  @$pb.TagNumber(3)
  set isNew($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIsNew() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsNew() => clearField(3);
}

class UpdatedRowPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdatedRowPB', createEmptyInstance: create)
    ..aOM<RowPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'row', subBuilder: RowPB.create)
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldIds')
    ..hasRequiredFields = false
  ;

  UpdatedRowPB._() : super();
  factory UpdatedRowPB({
    RowPB? row,
    $core.Iterable<$core.String>? fieldIds,
  }) {
    final _result = create();
    if (row != null) {
      _result.row = row;
    }
    if (fieldIds != null) {
      _result.fieldIds.addAll(fieldIds);
    }
    return _result;
  }
  factory UpdatedRowPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdatedRowPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdatedRowPB clone() => UpdatedRowPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdatedRowPB copyWith(void Function(UpdatedRowPB) updates) => super.copyWith((message) => updates(message as UpdatedRowPB)) as UpdatedRowPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdatedRowPB create() => UpdatedRowPB._();
  UpdatedRowPB createEmptyInstance() => create();
  static $pb.PbList<UpdatedRowPB> createRepeated() => $pb.PbList<UpdatedRowPB>();
  @$core.pragma('dart2js:noInline')
  static UpdatedRowPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdatedRowPB>(create);
  static UpdatedRowPB? _defaultInstance;

  @$pb.TagNumber(1)
  RowPB get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(RowPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => clearField(1);
  @$pb.TagNumber(1)
  RowPB ensureRow() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get fieldIds => $_getList(1);
}

class RowIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..hasRequiredFields = false
  ;

  RowIdPB._() : super();
  factory RowIdPB({
    $core.String? gridId,
    $core.String? rowId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    return _result;
  }
  factory RowIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RowIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RowIdPB clone() => RowIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RowIdPB copyWith(void Function(RowIdPB) updates) => super.copyWith((message) => updates(message as RowIdPB)) as RowIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RowIdPB create() => RowIdPB._();
  RowIdPB createEmptyInstance() => create();
  static $pb.PbList<RowIdPB> createRepeated() => $pb.PbList<RowIdPB>();
  @$core.pragma('dart2js:noInline')
  static RowIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowIdPB>(create);
  static RowIdPB? _defaultInstance;

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
}

class BlockRowIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockRowIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..hasRequiredFields = false
  ;

  BlockRowIdPB._() : super();
  factory BlockRowIdPB({
    $core.String? blockId,
    $core.String? rowId,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    return _result;
  }
  factory BlockRowIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockRowIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockRowIdPB clone() => BlockRowIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockRowIdPB copyWith(void Function(BlockRowIdPB) updates) => super.copyWith((message) => updates(message as BlockRowIdPB)) as BlockRowIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockRowIdPB create() => BlockRowIdPB._();
  BlockRowIdPB createEmptyInstance() => create();
  static $pb.PbList<BlockRowIdPB> createRepeated() => $pb.PbList<BlockRowIdPB>();
  @$core.pragma('dart2js:noInline')
  static BlockRowIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockRowIdPB>(create);
  static BlockRowIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get rowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set rowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowId() => clearField(2);
}

enum CreateTableRowPayloadPB_OneOfStartRowId {
  startRowId, 
  notSet
}

class CreateTableRowPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateTableRowPayloadPB_OneOfStartRowId> _CreateTableRowPayloadPB_OneOfStartRowIdByTag = {
    2 : CreateTableRowPayloadPB_OneOfStartRowId.startRowId,
    0 : CreateTableRowPayloadPB_OneOfStartRowId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateTableRowPayloadPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startRowId')
    ..hasRequiredFields = false
  ;

  CreateTableRowPayloadPB._() : super();
  factory CreateTableRowPayloadPB({
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
  factory CreateTableRowPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateTableRowPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateTableRowPayloadPB clone() => CreateTableRowPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateTableRowPayloadPB copyWith(void Function(CreateTableRowPayloadPB) updates) => super.copyWith((message) => updates(message as CreateTableRowPayloadPB)) as CreateTableRowPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateTableRowPayloadPB create() => CreateTableRowPayloadPB._();
  CreateTableRowPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateTableRowPayloadPB> createRepeated() => $pb.PbList<CreateTableRowPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateTableRowPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateTableRowPayloadPB>(create);
  static CreateTableRowPayloadPB? _defaultInstance;

  CreateTableRowPayloadPB_OneOfStartRowId whichOneOfStartRowId() => _CreateTableRowPayloadPB_OneOfStartRowIdByTag[$_whichOneof(0)]!;
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

