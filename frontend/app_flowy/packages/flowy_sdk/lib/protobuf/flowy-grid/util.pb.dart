///
//  Generated code. Do not modify.
//  source: util.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field_entities.pbenum.dart' as $0;

class FilterPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FilterPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$0.FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  FilterPB._() : super();
  factory FilterPB({
    $core.String? id,
    $core.String? fieldId,
    $0.FieldType? fieldType,
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory FilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FilterPB clone() => FilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FilterPB copyWith(void Function(FilterPB) updates) => super.copyWith((message) => updates(message as FilterPB)) as FilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FilterPB create() => FilterPB._();
  FilterPB createEmptyInstance() => create();
  static $pb.PbList<FilterPB> createRepeated() => $pb.PbList<FilterPB>();
  @$core.pragma('dart2js:noInline')
  static FilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FilterPB>(create);
  static FilterPB? _defaultInstance;

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
  $0.FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType($0.FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get data => $_getN(3);
  @$pb.TagNumber(4)
  set data($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => clearField(4);
}

class RepeatedFilterPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedFilterPB', createEmptyInstance: create)
    ..pc<FilterPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: FilterPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedFilterPB._() : super();
  factory RepeatedFilterPB({
    $core.Iterable<FilterPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedFilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedFilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedFilterPB clone() => RepeatedFilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedFilterPB copyWith(void Function(RepeatedFilterPB) updates) => super.copyWith((message) => updates(message as RepeatedFilterPB)) as RepeatedFilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedFilterPB create() => RepeatedFilterPB._();
  RepeatedFilterPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedFilterPB> createRepeated() => $pb.PbList<RepeatedFilterPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedFilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedFilterPB>(create);
  static RepeatedFilterPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FilterPB> get items => $_getList(0);
}

class DeleteFilterPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteFilterPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$0.FieldType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filterId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..hasRequiredFields = false
  ;

  DeleteFilterPayloadPB._() : super();
  factory DeleteFilterPayloadPB({
    $core.String? fieldId,
    $0.FieldType? fieldType,
    $core.String? filterId,
    $core.String? viewId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (filterId != null) {
      _result.filterId = filterId;
    }
    if (viewId != null) {
      _result.viewId = viewId;
    }
    return _result;
  }
  factory DeleteFilterPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteFilterPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteFilterPayloadPB clone() => DeleteFilterPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteFilterPayloadPB copyWith(void Function(DeleteFilterPayloadPB) updates) => super.copyWith((message) => updates(message as DeleteFilterPayloadPB)) as DeleteFilterPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteFilterPayloadPB create() => DeleteFilterPayloadPB._();
  DeleteFilterPayloadPB createEmptyInstance() => create();
  static $pb.PbList<DeleteFilterPayloadPB> createRepeated() => $pb.PbList<DeleteFilterPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static DeleteFilterPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteFilterPayloadPB>(create);
  static DeleteFilterPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $0.FieldType get fieldType => $_getN(1);
  @$pb.TagNumber(2)
  set fieldType($0.FieldType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldType() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get filterId => $_getSZ(2);
  @$pb.TagNumber(3)
  set filterId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFilterId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilterId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get viewId => $_getSZ(3);
  @$pb.TagNumber(4)
  set viewId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasViewId() => $_has(3);
  @$pb.TagNumber(4)
  void clearViewId() => clearField(4);
}

enum AlterFilterPayloadPB_OneOfFilterId {
  filterId, 
  notSet
}

class AlterFilterPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, AlterFilterPayloadPB_OneOfFilterId> _AlterFilterPayloadPB_OneOfFilterIdByTag = {
    3 : AlterFilterPayloadPB_OneOfFilterId.filterId,
    0 : AlterFilterPayloadPB_OneOfFilterId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AlterFilterPayloadPB', createEmptyInstance: create)
    ..oo(0, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$0.FieldType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filterId')
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..hasRequiredFields = false
  ;

  AlterFilterPayloadPB._() : super();
  factory AlterFilterPayloadPB({
    $core.String? fieldId,
    $0.FieldType? fieldType,
    $core.String? filterId,
    $core.List<$core.int>? data,
    $core.String? viewId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (filterId != null) {
      _result.filterId = filterId;
    }
    if (data != null) {
      _result.data = data;
    }
    if (viewId != null) {
      _result.viewId = viewId;
    }
    return _result;
  }
  factory AlterFilterPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AlterFilterPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AlterFilterPayloadPB clone() => AlterFilterPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AlterFilterPayloadPB copyWith(void Function(AlterFilterPayloadPB) updates) => super.copyWith((message) => updates(message as AlterFilterPayloadPB)) as AlterFilterPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AlterFilterPayloadPB create() => AlterFilterPayloadPB._();
  AlterFilterPayloadPB createEmptyInstance() => create();
  static $pb.PbList<AlterFilterPayloadPB> createRepeated() => $pb.PbList<AlterFilterPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static AlterFilterPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AlterFilterPayloadPB>(create);
  static AlterFilterPayloadPB? _defaultInstance;

  AlterFilterPayloadPB_OneOfFilterId whichOneOfFilterId() => _AlterFilterPayloadPB_OneOfFilterIdByTag[$_whichOneof(0)]!;
  void clearOneOfFilterId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $0.FieldType get fieldType => $_getN(1);
  @$pb.TagNumber(2)
  set fieldType($0.FieldType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldType() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get filterId => $_getSZ(2);
  @$pb.TagNumber(3)
  set filterId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFilterId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilterId() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get data => $_getN(3);
  @$pb.TagNumber(4)
  set data($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get viewId => $_getSZ(4);
  @$pb.TagNumber(5)
  set viewId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasViewId() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewId() => clearField(5);
}

