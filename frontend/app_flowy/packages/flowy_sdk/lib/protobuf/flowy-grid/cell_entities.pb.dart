///
//  Generated code. Do not modify.
//  source: cell_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field_entities.pbenum.dart' as $0;

class CreateSelectOptionPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateSelectOptionPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'optionName')
    ..hasRequiredFields = false
  ;

  CreateSelectOptionPayloadPB._() : super();
  factory CreateSelectOptionPayloadPB({
    $core.String? fieldId,
    $core.String? gridId,
    $core.String? optionName,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (optionName != null) {
      _result.optionName = optionName;
    }
    return _result;
  }
  factory CreateSelectOptionPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateSelectOptionPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateSelectOptionPayloadPB clone() => CreateSelectOptionPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateSelectOptionPayloadPB copyWith(void Function(CreateSelectOptionPayloadPB) updates) => super.copyWith((message) => updates(message as CreateSelectOptionPayloadPB)) as CreateSelectOptionPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateSelectOptionPayloadPB create() => CreateSelectOptionPayloadPB._();
  CreateSelectOptionPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateSelectOptionPayloadPB> createRepeated() => $pb.PbList<CreateSelectOptionPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateSelectOptionPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateSelectOptionPayloadPB>(create);
  static CreateSelectOptionPayloadPB? _defaultInstance;

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
  $core.String get optionName => $_getSZ(2);
  @$pb.TagNumber(3)
  set optionName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOptionName() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptionName() => clearField(3);
}

class CellPathPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellPathPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..hasRequiredFields = false
  ;

  CellPathPB._() : super();
  factory CellPathPB({
    $core.String? viewId,
    $core.String? fieldId,
    $core.String? rowId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    return _result;
  }
  factory CellPathPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellPathPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellPathPB clone() => CellPathPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellPathPB copyWith(void Function(CellPathPB) updates) => super.copyWith((message) => updates(message as CellPathPB)) as CellPathPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellPathPB create() => CellPathPB._();
  CellPathPB createEmptyInstance() => create();
  static $pb.PbList<CellPathPB> createRepeated() => $pb.PbList<CellPathPB>();
  @$core.pragma('dart2js:noInline')
  static CellPathPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellPathPB>(create);
  static CellPathPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

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
}

enum CellPB_OneOfFieldType {
  fieldType, 
  notSet
}

class CellPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CellPB_OneOfFieldType> _CellPB_OneOfFieldTypeByTag = {
    3 : CellPB_OneOfFieldType.fieldType,
    0 : CellPB_OneOfFieldType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellPB', createEmptyInstance: create)
    ..oo(0, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..e<$0.FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..hasRequiredFields = false
  ;

  CellPB._() : super();
  factory CellPB({
    $core.String? fieldId,
    $core.List<$core.int>? data,
    $0.FieldType? fieldType,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (data != null) {
      _result.data = data;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    return _result;
  }
  factory CellPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellPB clone() => CellPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellPB copyWith(void Function(CellPB) updates) => super.copyWith((message) => updates(message as CellPB)) as CellPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellPB create() => CellPB._();
  CellPB createEmptyInstance() => create();
  static $pb.PbList<CellPB> createRepeated() => $pb.PbList<CellPB>();
  @$core.pragma('dart2js:noInline')
  static CellPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellPB>(create);
  static CellPB? _defaultInstance;

  CellPB_OneOfFieldType whichOneOfFieldType() => _CellPB_OneOfFieldTypeByTag[$_whichOneof(0)]!;
  void clearOneOfFieldType() => clearField($_whichOneof(0));

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

  @$pb.TagNumber(3)
  $0.FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType($0.FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);
}

class RepeatedCellPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedCellPB', createEmptyInstance: create)
    ..pc<CellPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: CellPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedCellPB._() : super();
  factory RepeatedCellPB({
    $core.Iterable<CellPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedCellPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedCellPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedCellPB clone() => RepeatedCellPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedCellPB copyWith(void Function(RepeatedCellPB) updates) => super.copyWith((message) => updates(message as RepeatedCellPB)) as RepeatedCellPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedCellPB create() => RepeatedCellPB._();
  RepeatedCellPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedCellPB> createRepeated() => $pb.PbList<RepeatedCellPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedCellPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedCellPB>(create);
  static RepeatedCellPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<CellPB> get items => $_getList(0);
}

class CellChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'typeCellData')
    ..hasRequiredFields = false
  ;

  CellChangesetPB._() : super();
  factory CellChangesetPB({
    $core.String? gridId,
    $core.String? rowId,
    $core.String? fieldId,
    $core.String? typeCellData,
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
    if (typeCellData != null) {
      _result.typeCellData = typeCellData;
    }
    return _result;
  }
  factory CellChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellChangesetPB clone() => CellChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellChangesetPB copyWith(void Function(CellChangesetPB) updates) => super.copyWith((message) => updates(message as CellChangesetPB)) as CellChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellChangesetPB create() => CellChangesetPB._();
  CellChangesetPB createEmptyInstance() => create();
  static $pb.PbList<CellChangesetPB> createRepeated() => $pb.PbList<CellChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static CellChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellChangesetPB>(create);
  static CellChangesetPB? _defaultInstance;

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
  $core.String get typeCellData => $_getSZ(3);
  @$pb.TagNumber(4)
  set typeCellData($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTypeCellData() => $_has(3);
  @$pb.TagNumber(4)
  void clearTypeCellData() => clearField(4);
}

