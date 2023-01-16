///
//  Generated code. Do not modify.
//  source: grid_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field_entities.pb.dart' as $0;
import 'row_entities.pb.dart' as $1;

class GridPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..pc<$0.FieldIdPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fields', $pb.PbFieldType.PM, subBuilder: $0.FieldIdPB.create)
    ..pc<$1.RowPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rows', $pb.PbFieldType.PM, subBuilder: $1.RowPB.create)
    ..hasRequiredFields = false
  ;

  GridPB._() : super();
  factory GridPB({
    $core.String? id,
    $core.Iterable<$0.FieldIdPB>? fields,
    $core.Iterable<$1.RowPB>? rows,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fields != null) {
      _result.fields.addAll(fields);
    }
    if (rows != null) {
      _result.rows.addAll(rows);
    }
    return _result;
  }
  factory GridPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridPB clone() => GridPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridPB copyWith(void Function(GridPB) updates) => super.copyWith((message) => updates(message as GridPB)) as GridPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridPB create() => GridPB._();
  GridPB createEmptyInstance() => create();
  static $pb.PbList<GridPB> createRepeated() => $pb.PbList<GridPB>();
  @$core.pragma('dart2js:noInline')
  static GridPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridPB>(create);
  static GridPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$0.FieldIdPB> get fields => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$1.RowPB> get rows => $_getList(2);
}

class CreateGridPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateGridPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..hasRequiredFields = false
  ;

  CreateGridPayloadPB._() : super();
  factory CreateGridPayloadPB({
    $core.String? name,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    return _result;
  }
  factory CreateGridPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateGridPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateGridPayloadPB clone() => CreateGridPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateGridPayloadPB copyWith(void Function(CreateGridPayloadPB) updates) => super.copyWith((message) => updates(message as CreateGridPayloadPB)) as CreateGridPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateGridPayloadPB create() => CreateGridPayloadPB._();
  CreateGridPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateGridPayloadPB> createRepeated() => $pb.PbList<CreateGridPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateGridPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateGridPayloadPB>(create);
  static CreateGridPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);
}

class GridIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  GridIdPB._() : super();
  factory GridIdPB({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory GridIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridIdPB clone() => GridIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridIdPB copyWith(void Function(GridIdPB) updates) => super.copyWith((message) => updates(message as GridIdPB)) as GridIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridIdPB create() => GridIdPB._();
  GridIdPB createEmptyInstance() => create();
  static $pb.PbList<GridIdPB> createRepeated() => $pb.PbList<GridIdPB>();
  @$core.pragma('dart2js:noInline')
  static GridIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridIdPB>(create);
  static GridIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class GridBlockIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridBlockIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  GridBlockIdPB._() : super();
  factory GridBlockIdPB({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory GridBlockIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridBlockIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridBlockIdPB clone() => GridBlockIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridBlockIdPB copyWith(void Function(GridBlockIdPB) updates) => super.copyWith((message) => updates(message as GridBlockIdPB)) as GridBlockIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridBlockIdPB create() => GridBlockIdPB._();
  GridBlockIdPB createEmptyInstance() => create();
  static $pb.PbList<GridBlockIdPB> createRepeated() => $pb.PbList<GridBlockIdPB>();
  @$core.pragma('dart2js:noInline')
  static GridBlockIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridBlockIdPB>(create);
  static GridBlockIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class MoveFieldPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveFieldPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toIndex', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  MoveFieldPayloadPB._() : super();
  factory MoveFieldPayloadPB({
    $core.String? gridId,
    $core.String? fieldId,
    $core.int? fromIndex,
    $core.int? toIndex,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fromIndex != null) {
      _result.fromIndex = fromIndex;
    }
    if (toIndex != null) {
      _result.toIndex = toIndex;
    }
    return _result;
  }
  factory MoveFieldPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveFieldPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveFieldPayloadPB clone() => MoveFieldPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveFieldPayloadPB copyWith(void Function(MoveFieldPayloadPB) updates) => super.copyWith((message) => updates(message as MoveFieldPayloadPB)) as MoveFieldPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveFieldPayloadPB create() => MoveFieldPayloadPB._();
  MoveFieldPayloadPB createEmptyInstance() => create();
  static $pb.PbList<MoveFieldPayloadPB> createRepeated() => $pb.PbList<MoveFieldPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static MoveFieldPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveFieldPayloadPB>(create);
  static MoveFieldPayloadPB? _defaultInstance;

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
}

class MoveRowPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveRowPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromRowId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toRowId')
    ..hasRequiredFields = false
  ;

  MoveRowPayloadPB._() : super();
  factory MoveRowPayloadPB({
    $core.String? viewId,
    $core.String? fromRowId,
    $core.String? toRowId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (fromRowId != null) {
      _result.fromRowId = fromRowId;
    }
    if (toRowId != null) {
      _result.toRowId = toRowId;
    }
    return _result;
  }
  factory MoveRowPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveRowPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveRowPayloadPB clone() => MoveRowPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveRowPayloadPB copyWith(void Function(MoveRowPayloadPB) updates) => super.copyWith((message) => updates(message as MoveRowPayloadPB)) as MoveRowPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveRowPayloadPB create() => MoveRowPayloadPB._();
  MoveRowPayloadPB createEmptyInstance() => create();
  static $pb.PbList<MoveRowPayloadPB> createRepeated() => $pb.PbList<MoveRowPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static MoveRowPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveRowPayloadPB>(create);
  static MoveRowPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromRowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromRowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFromRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromRowId() => clearField(2);

  @$pb.TagNumber(4)
  $core.String get toRowId => $_getSZ(2);
  @$pb.TagNumber(4)
  set toRowId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasToRowId() => $_has(2);
  @$pb.TagNumber(4)
  void clearToRowId() => clearField(4);
}

enum MoveGroupRowPayloadPB_OneOfToRowId {
  toRowId, 
  notSet
}

class MoveGroupRowPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, MoveGroupRowPayloadPB_OneOfToRowId> _MoveGroupRowPayloadPB_OneOfToRowIdByTag = {
    4 : MoveGroupRowPayloadPB_OneOfToRowId.toRowId,
    0 : MoveGroupRowPayloadPB_OneOfToRowId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveGroupRowPayloadPB', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromRowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toGroupId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toRowId')
    ..hasRequiredFields = false
  ;

  MoveGroupRowPayloadPB._() : super();
  factory MoveGroupRowPayloadPB({
    $core.String? viewId,
    $core.String? fromRowId,
    $core.String? toGroupId,
    $core.String? toRowId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (fromRowId != null) {
      _result.fromRowId = fromRowId;
    }
    if (toGroupId != null) {
      _result.toGroupId = toGroupId;
    }
    if (toRowId != null) {
      _result.toRowId = toRowId;
    }
    return _result;
  }
  factory MoveGroupRowPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveGroupRowPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveGroupRowPayloadPB clone() => MoveGroupRowPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveGroupRowPayloadPB copyWith(void Function(MoveGroupRowPayloadPB) updates) => super.copyWith((message) => updates(message as MoveGroupRowPayloadPB)) as MoveGroupRowPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveGroupRowPayloadPB create() => MoveGroupRowPayloadPB._();
  MoveGroupRowPayloadPB createEmptyInstance() => create();
  static $pb.PbList<MoveGroupRowPayloadPB> createRepeated() => $pb.PbList<MoveGroupRowPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static MoveGroupRowPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveGroupRowPayloadPB>(create);
  static MoveGroupRowPayloadPB? _defaultInstance;

  MoveGroupRowPayloadPB_OneOfToRowId whichOneOfToRowId() => _MoveGroupRowPayloadPB_OneOfToRowIdByTag[$_whichOneof(0)]!;
  void clearOneOfToRowId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromRowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromRowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFromRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromRowId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get toGroupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set toGroupId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasToGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearToGroupId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get toRowId => $_getSZ(3);
  @$pb.TagNumber(4)
  set toRowId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasToRowId() => $_has(3);
  @$pb.TagNumber(4)
  void clearToRowId() => clearField(4);
}

