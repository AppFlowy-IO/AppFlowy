///
//  Generated code. Do not modify.
//  source: meta.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'meta.pbenum.dart';

export 'meta.pbenum.dart';

class GridMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridMeta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..pc<FieldMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fields', $pb.PbFieldType.PM, subBuilder: FieldMeta.create)
    ..pc<GridBlockMeta>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blocks', $pb.PbFieldType.PM, subBuilder: GridBlockMeta.create)
    ..hasRequiredFields = false
  ;

  GridMeta._() : super();
  factory GridMeta({
    $core.String? gridId,
    $core.Iterable<FieldMeta>? fields,
    $core.Iterable<GridBlockMeta>? blocks,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fields != null) {
      _result.fields.addAll(fields);
    }
    if (blocks != null) {
      _result.blocks.addAll(blocks);
    }
    return _result;
  }
  factory GridMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridMeta clone() => GridMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridMeta copyWith(void Function(GridMeta) updates) => super.copyWith((message) => updates(message as GridMeta)) as GridMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridMeta create() => GridMeta._();
  GridMeta createEmptyInstance() => create();
  static $pb.PbList<GridMeta> createRepeated() => $pb.PbList<GridMeta>();
  @$core.pragma('dart2js:noInline')
  static GridMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridMeta>(create);
  static GridMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<FieldMeta> get fields => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<GridBlockMeta> get blocks => $_getList(2);
}

class GridBlockMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlockMeta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startRowIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowCount', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  GridBlockMeta._() : super();
  factory GridBlockMeta({
    $core.String? blockId,
    $core.int? startRowIndex,
    $core.int? rowCount,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (startRowIndex != null) {
      _result.startRowIndex = startRowIndex;
    }
    if (rowCount != null) {
      _result.rowCount = rowCount;
    }
    return _result;
  }
  factory GridBlockMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridBlockMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridBlockMeta clone() => GridBlockMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridBlockMeta copyWith(void Function(GridBlockMeta) updates) => super.copyWith((message) => updates(message as GridBlockMeta)) as GridBlockMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridBlockMeta create() => GridBlockMeta._();
  GridBlockMeta createEmptyInstance() => create();
  static $pb.PbList<GridBlockMeta> createRepeated() => $pb.PbList<GridBlockMeta>();
  @$core.pragma('dart2js:noInline')
  static GridBlockMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridBlockMeta>(create);
  static GridBlockMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get startRowIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set startRowIndex($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStartRowIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartRowIndex() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get rowCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set rowCount($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRowCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowCount() => clearField(3);
}

class GridBlockMetaData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlockMetaData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..pc<RowMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowMetas', $pb.PbFieldType.PM, subBuilder: RowMeta.create)
    ..hasRequiredFields = false
  ;

  GridBlockMetaData._() : super();
  factory GridBlockMetaData({
    $core.String? blockId,
    $core.Iterable<RowMeta>? rowMetas,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (rowMetas != null) {
      _result.rowMetas.addAll(rowMetas);
    }
    return _result;
  }
  factory GridBlockMetaData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridBlockMetaData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridBlockMetaData clone() => GridBlockMetaData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridBlockMetaData copyWith(void Function(GridBlockMetaData) updates) => super.copyWith((message) => updates(message as GridBlockMetaData)) as GridBlockMetaData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridBlockMetaData create() => GridBlockMetaData._();
  GridBlockMetaData createEmptyInstance() => create();
  static $pb.PbList<GridBlockMetaData> createRepeated() => $pb.PbList<GridBlockMetaData>();
  @$core.pragma('dart2js:noInline')
  static GridBlockMetaData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridBlockMetaData>(create);
  static GridBlockMetaData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<RowMeta> get rowMetas => $_getList(1);
}

class FieldMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldMeta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<FieldType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..aOS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptions')
    ..hasRequiredFields = false
  ;

  FieldMeta._() : super();
  factory FieldMeta({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    FieldType? fieldType,
    $core.bool? frozen,
    $core.bool? visibility,
    $core.int? width,
    $core.String? typeOptions,
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
    if (typeOptions != null) {
      _result.typeOptions = typeOptions;
    }
    return _result;
  }
  factory FieldMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldMeta clone() => FieldMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldMeta copyWith(void Function(FieldMeta) updates) => super.copyWith((message) => updates(message as FieldMeta)) as FieldMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldMeta create() => FieldMeta._();
  FieldMeta createEmptyInstance() => create();
  static $pb.PbList<FieldMeta> createRepeated() => $pb.PbList<FieldMeta>();
  @$core.pragma('dart2js:noInline')
  static FieldMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldMeta>(create);
  static FieldMeta? _defaultInstance;

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
  $core.String get typeOptions => $_getSZ(7);
  @$pb.TagNumber(8)
  set typeOptions($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTypeOptions() => $_has(7);
  @$pb.TagNumber(8)
  void clearTypeOptions() => clearField(8);
}

enum FieldChangeset_OneOfName {
  name, 
  notSet
}

enum FieldChangeset_OneOfDesc {
  desc, 
  notSet
}

enum FieldChangeset_OneOfFieldType {
  fieldType, 
  notSet
}

enum FieldChangeset_OneOfFrozen {
  frozen, 
  notSet
}

enum FieldChangeset_OneOfVisibility {
  visibility, 
  notSet
}

enum FieldChangeset_OneOfWidth {
  width, 
  notSet
}

enum FieldChangeset_OneOfTypeOptions {
  typeOptions, 
  notSet
}

class FieldChangeset extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, FieldChangeset_OneOfName> _FieldChangeset_OneOfNameByTag = {
    2 : FieldChangeset_OneOfName.name,
    0 : FieldChangeset_OneOfName.notSet
  };
  static const $core.Map<$core.int, FieldChangeset_OneOfDesc> _FieldChangeset_OneOfDescByTag = {
    3 : FieldChangeset_OneOfDesc.desc,
    0 : FieldChangeset_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, FieldChangeset_OneOfFieldType> _FieldChangeset_OneOfFieldTypeByTag = {
    4 : FieldChangeset_OneOfFieldType.fieldType,
    0 : FieldChangeset_OneOfFieldType.notSet
  };
  static const $core.Map<$core.int, FieldChangeset_OneOfFrozen> _FieldChangeset_OneOfFrozenByTag = {
    5 : FieldChangeset_OneOfFrozen.frozen,
    0 : FieldChangeset_OneOfFrozen.notSet
  };
  static const $core.Map<$core.int, FieldChangeset_OneOfVisibility> _FieldChangeset_OneOfVisibilityByTag = {
    6 : FieldChangeset_OneOfVisibility.visibility,
    0 : FieldChangeset_OneOfVisibility.notSet
  };
  static const $core.Map<$core.int, FieldChangeset_OneOfWidth> _FieldChangeset_OneOfWidthByTag = {
    7 : FieldChangeset_OneOfWidth.width,
    0 : FieldChangeset_OneOfWidth.notSet
  };
  static const $core.Map<$core.int, FieldChangeset_OneOfTypeOptions> _FieldChangeset_OneOfTypeOptionsByTag = {
    8 : FieldChangeset_OneOfTypeOptions.typeOptions,
    0 : FieldChangeset_OneOfTypeOptions.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldChangeset', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..oo(4, [6])
    ..oo(5, [7])
    ..oo(6, [8])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<FieldType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: FieldType.RichText, valueOf: FieldType.valueOf, enumValues: FieldType.values)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'frozen')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width', $pb.PbFieldType.O3)
    ..aOS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeOptions')
    ..hasRequiredFields = false
  ;

  FieldChangeset._() : super();
  factory FieldChangeset({
    $core.String? fieldId,
    $core.String? name,
    $core.String? desc,
    FieldType? fieldType,
    $core.bool? frozen,
    $core.bool? visibility,
    $core.int? width,
    $core.String? typeOptions,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
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
    if (typeOptions != null) {
      _result.typeOptions = typeOptions;
    }
    return _result;
  }
  factory FieldChangeset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldChangeset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldChangeset clone() => FieldChangeset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldChangeset copyWith(void Function(FieldChangeset) updates) => super.copyWith((message) => updates(message as FieldChangeset)) as FieldChangeset; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldChangeset create() => FieldChangeset._();
  FieldChangeset createEmptyInstance() => create();
  static $pb.PbList<FieldChangeset> createRepeated() => $pb.PbList<FieldChangeset>();
  @$core.pragma('dart2js:noInline')
  static FieldChangeset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldChangeset>(create);
  static FieldChangeset? _defaultInstance;

  FieldChangeset_OneOfName whichOneOfName() => _FieldChangeset_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  FieldChangeset_OneOfDesc whichOneOfDesc() => _FieldChangeset_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  FieldChangeset_OneOfFieldType whichOneOfFieldType() => _FieldChangeset_OneOfFieldTypeByTag[$_whichOneof(2)]!;
  void clearOneOfFieldType() => clearField($_whichOneof(2));

  FieldChangeset_OneOfFrozen whichOneOfFrozen() => _FieldChangeset_OneOfFrozenByTag[$_whichOneof(3)]!;
  void clearOneOfFrozen() => clearField($_whichOneof(3));

  FieldChangeset_OneOfVisibility whichOneOfVisibility() => _FieldChangeset_OneOfVisibilityByTag[$_whichOneof(4)]!;
  void clearOneOfVisibility() => clearField($_whichOneof(4));

  FieldChangeset_OneOfWidth whichOneOfWidth() => _FieldChangeset_OneOfWidthByTag[$_whichOneof(5)]!;
  void clearOneOfWidth() => clearField($_whichOneof(5));

  FieldChangeset_OneOfTypeOptions whichOneOfTypeOptions() => _FieldChangeset_OneOfTypeOptionsByTag[$_whichOneof(6)]!;
  void clearOneOfTypeOptions() => clearField($_whichOneof(6));

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

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
  $core.String get typeOptions => $_getSZ(7);
  @$pb.TagNumber(8)
  set typeOptions($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTypeOptions() => $_has(7);
  @$pb.TagNumber(8)
  void clearTypeOptions() => clearField(8);
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

class RowMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowMeta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..m<$core.String, CellMeta>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellByFieldId', entryClassName: 'RowMeta.CellByFieldIdEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: CellMeta.create)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.O3)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..hasRequiredFields = false
  ;

  RowMeta._() : super();
  factory RowMeta({
    $core.String? id,
    $core.String? blockId,
    $core.Map<$core.String, CellMeta>? cellByFieldId,
    $core.int? height,
    $core.bool? visibility,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (cellByFieldId != null) {
      _result.cellByFieldId.addAll(cellByFieldId);
    }
    if (height != null) {
      _result.height = height;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    return _result;
  }
  factory RowMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RowMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RowMeta clone() => RowMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RowMeta copyWith(void Function(RowMeta) updates) => super.copyWith((message) => updates(message as RowMeta)) as RowMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RowMeta create() => RowMeta._();
  RowMeta createEmptyInstance() => create();
  static $pb.PbList<RowMeta> createRepeated() => $pb.PbList<RowMeta>();
  @$core.pragma('dart2js:noInline')
  static RowMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowMeta>(create);
  static RowMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get blockId => $_getSZ(1);
  @$pb.TagNumber(2)
  set blockId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBlockId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlockId() => clearField(2);

  @$pb.TagNumber(3)
  $core.Map<$core.String, CellMeta> get cellByFieldId => $_getMap(2);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get visibility => $_getBF(4);
  @$pb.TagNumber(5)
  set visibility($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasVisibility() => $_has(4);
  @$pb.TagNumber(5)
  void clearVisibility() => clearField(5);
}

enum RowMetaChangeset_OneOfHeight {
  height, 
  notSet
}

enum RowMetaChangeset_OneOfVisibility {
  visibility, 
  notSet
}

class RowMetaChangeset extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, RowMetaChangeset_OneOfHeight> _RowMetaChangeset_OneOfHeightByTag = {
    2 : RowMetaChangeset_OneOfHeight.height,
    0 : RowMetaChangeset_OneOfHeight.notSet
  };
  static const $core.Map<$core.int, RowMetaChangeset_OneOfVisibility> _RowMetaChangeset_OneOfVisibilityByTag = {
    3 : RowMetaChangeset_OneOfVisibility.visibility,
    0 : RowMetaChangeset_OneOfVisibility.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowMetaChangeset', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.O3)
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility')
    ..m<$core.String, CellMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellByFieldId', entryClassName: 'RowMetaChangeset.CellByFieldIdEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: CellMeta.create)
    ..hasRequiredFields = false
  ;

  RowMetaChangeset._() : super();
  factory RowMetaChangeset({
    $core.String? rowId,
    $core.int? height,
    $core.bool? visibility,
    $core.Map<$core.String, CellMeta>? cellByFieldId,
  }) {
    final _result = create();
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (height != null) {
      _result.height = height;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    if (cellByFieldId != null) {
      _result.cellByFieldId.addAll(cellByFieldId);
    }
    return _result;
  }
  factory RowMetaChangeset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RowMetaChangeset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RowMetaChangeset clone() => RowMetaChangeset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RowMetaChangeset copyWith(void Function(RowMetaChangeset) updates) => super.copyWith((message) => updates(message as RowMetaChangeset)) as RowMetaChangeset; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RowMetaChangeset create() => RowMetaChangeset._();
  RowMetaChangeset createEmptyInstance() => create();
  static $pb.PbList<RowMetaChangeset> createRepeated() => $pb.PbList<RowMetaChangeset>();
  @$core.pragma('dart2js:noInline')
  static RowMetaChangeset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowMetaChangeset>(create);
  static RowMetaChangeset? _defaultInstance;

  RowMetaChangeset_OneOfHeight whichOneOfHeight() => _RowMetaChangeset_OneOfHeightByTag[$_whichOneof(0)]!;
  void clearOneOfHeight() => clearField($_whichOneof(0));

  RowMetaChangeset_OneOfVisibility whichOneOfVisibility() => _RowMetaChangeset_OneOfVisibilityByTag[$_whichOneof(1)]!;
  void clearOneOfVisibility() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get rowId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rowId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRowId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRowId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get visibility => $_getBF(2);
  @$pb.TagNumber(3)
  set visibility($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearVisibility() => clearField(3);

  @$pb.TagNumber(4)
  $core.Map<$core.String, CellMeta> get cellByFieldId => $_getMap(3);
}

class CellMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellMeta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  CellMeta._() : super();
  factory CellMeta({
    $core.String? fieldId,
    $core.String? data,
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
  factory CellMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellMeta clone() => CellMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellMeta copyWith(void Function(CellMeta) updates) => super.copyWith((message) => updates(message as CellMeta)) as CellMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellMeta create() => CellMeta._();
  CellMeta createEmptyInstance() => create();
  static $pb.PbList<CellMeta> createRepeated() => $pb.PbList<CellMeta>();
  @$core.pragma('dart2js:noInline')
  static CellMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellMeta>(create);
  static CellMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

enum CellMetaChangeset_OneOfData {
  data, 
  notSet
}

class CellMetaChangeset extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CellMetaChangeset_OneOfData> _CellMetaChangeset_OneOfDataByTag = {
    4 : CellMetaChangeset_OneOfData.data,
    0 : CellMetaChangeset_OneOfData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellMetaChangeset', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  CellMetaChangeset._() : super();
  factory CellMetaChangeset({
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
  factory CellMetaChangeset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellMetaChangeset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellMetaChangeset clone() => CellMetaChangeset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellMetaChangeset copyWith(void Function(CellMetaChangeset) updates) => super.copyWith((message) => updates(message as CellMetaChangeset)) as CellMetaChangeset; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellMetaChangeset create() => CellMetaChangeset._();
  CellMetaChangeset createEmptyInstance() => create();
  static $pb.PbList<CellMetaChangeset> createRepeated() => $pb.PbList<CellMetaChangeset>();
  @$core.pragma('dart2js:noInline')
  static CellMetaChangeset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellMetaChangeset>(create);
  static CellMetaChangeset? _defaultInstance;

  CellMetaChangeset_OneOfData whichOneOfData() => _CellMetaChangeset_OneOfDataByTag[$_whichOneof(0)]!;
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

class BuildGridContext extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildGridContext', createEmptyInstance: create)
    ..pc<FieldMeta>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldMetas', $pb.PbFieldType.PM, subBuilder: FieldMeta.create)
    ..aOM<GridBlockMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridBlock', subBuilder: GridBlockMeta.create)
    ..aOM<GridBlockMetaData>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridBlockMetaData', subBuilder: GridBlockMetaData.create)
    ..hasRequiredFields = false
  ;

  BuildGridContext._() : super();
  factory BuildGridContext({
    $core.Iterable<FieldMeta>? fieldMetas,
    GridBlockMeta? gridBlock,
    GridBlockMetaData? gridBlockMetaData,
  }) {
    final _result = create();
    if (fieldMetas != null) {
      _result.fieldMetas.addAll(fieldMetas);
    }
    if (gridBlock != null) {
      _result.gridBlock = gridBlock;
    }
    if (gridBlockMetaData != null) {
      _result.gridBlockMetaData = gridBlockMetaData;
    }
    return _result;
  }
  factory BuildGridContext.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildGridContext.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildGridContext clone() => BuildGridContext()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildGridContext copyWith(void Function(BuildGridContext) updates) => super.copyWith((message) => updates(message as BuildGridContext)) as BuildGridContext; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildGridContext create() => BuildGridContext._();
  BuildGridContext createEmptyInstance() => create();
  static $pb.PbList<BuildGridContext> createRepeated() => $pb.PbList<BuildGridContext>();
  @$core.pragma('dart2js:noInline')
  static BuildGridContext getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildGridContext>(create);
  static BuildGridContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FieldMeta> get fieldMetas => $_getList(0);

  @$pb.TagNumber(2)
  GridBlockMeta get gridBlock => $_getN(1);
  @$pb.TagNumber(2)
  set gridBlock(GridBlockMeta v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridBlock() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridBlock() => clearField(2);
  @$pb.TagNumber(2)
  GridBlockMeta ensureGridBlock() => $_ensure(1);

  @$pb.TagNumber(3)
  GridBlockMetaData get gridBlockMetaData => $_getN(2);
  @$pb.TagNumber(3)
  set gridBlockMetaData(GridBlockMetaData v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGridBlockMetaData() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridBlockMetaData() => clearField(3);
  @$pb.TagNumber(3)
  GridBlockMetaData ensureGridBlockMetaData() => $_ensure(2);
}

