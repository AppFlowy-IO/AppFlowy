///
//  Generated code. Do not modify.
//  source: sort_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field_entities.pbenum.dart' as $0;
import 'sort_entities.pbenum.dart';

export 'sort_entities.pbenum.dart';

class GridSortPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridSortPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$0.FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..e<GridSortConditionPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: GridSortConditionPB.Ascending, valueOf: GridSortConditionPB.valueOf, enumValues: GridSortConditionPB.values)
    ..hasRequiredFields = false
  ;

  GridSortPB._() : super();
  factory GridSortPB({
    $core.String? id,
    $core.String? fieldId,
    $0.FieldType? fieldType,
    GridSortConditionPB? condition,
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
    if (condition != null) {
      _result.condition = condition;
    }
    return _result;
  }
  factory GridSortPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridSortPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridSortPB clone() => GridSortPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridSortPB copyWith(void Function(GridSortPB) updates) => super.copyWith((message) => updates(message as GridSortPB)) as GridSortPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridSortPB create() => GridSortPB._();
  GridSortPB createEmptyInstance() => create();
  static $pb.PbList<GridSortPB> createRepeated() => $pb.PbList<GridSortPB>();
  @$core.pragma('dart2js:noInline')
  static GridSortPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridSortPB>(create);
  static GridSortPB? _defaultInstance;

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
  GridSortConditionPB get condition => $_getN(3);
  @$pb.TagNumber(4)
  set condition(GridSortConditionPB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCondition() => $_has(3);
  @$pb.TagNumber(4)
  void clearCondition() => clearField(4);
}

enum AlterSortPayloadPB_OneOfSortId {
  sortId, 
  notSet
}

class AlterSortPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, AlterSortPayloadPB_OneOfSortId> _AlterSortPayloadPB_OneOfSortIdByTag = {
    4 : AlterSortPayloadPB_OneOfSortId.sortId,
    0 : AlterSortPayloadPB_OneOfSortId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AlterSortPayloadPB', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$0.FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sortId')
    ..e<GridSortConditionPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: GridSortConditionPB.Ascending, valueOf: GridSortConditionPB.valueOf, enumValues: GridSortConditionPB.values)
    ..hasRequiredFields = false
  ;

  AlterSortPayloadPB._() : super();
  factory AlterSortPayloadPB({
    $core.String? viewId,
    $core.String? fieldId,
    $0.FieldType? fieldType,
    $core.String? sortId,
    GridSortConditionPB? condition,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (sortId != null) {
      _result.sortId = sortId;
    }
    if (condition != null) {
      _result.condition = condition;
    }
    return _result;
  }
  factory AlterSortPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AlterSortPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AlterSortPayloadPB clone() => AlterSortPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AlterSortPayloadPB copyWith(void Function(AlterSortPayloadPB) updates) => super.copyWith((message) => updates(message as AlterSortPayloadPB)) as AlterSortPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AlterSortPayloadPB create() => AlterSortPayloadPB._();
  AlterSortPayloadPB createEmptyInstance() => create();
  static $pb.PbList<AlterSortPayloadPB> createRepeated() => $pb.PbList<AlterSortPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static AlterSortPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AlterSortPayloadPB>(create);
  static AlterSortPayloadPB? _defaultInstance;

  AlterSortPayloadPB_OneOfSortId whichOneOfSortId() => _AlterSortPayloadPB_OneOfSortIdByTag[$_whichOneof(0)]!;
  void clearOneOfSortId() => clearField($_whichOneof(0));

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
  $0.FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType($0.FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get sortId => $_getSZ(3);
  @$pb.TagNumber(4)
  set sortId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSortId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSortId() => clearField(4);

  @$pb.TagNumber(5)
  GridSortConditionPB get condition => $_getN(4);
  @$pb.TagNumber(5)
  set condition(GridSortConditionPB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasCondition() => $_has(4);
  @$pb.TagNumber(5)
  void clearCondition() => clearField(5);
}

class DeleteSortPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteSortPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..e<$0.FieldType>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldType', $pb.PbFieldType.OE, defaultOrMaker: $0.FieldType.RichText, valueOf: $0.FieldType.valueOf, enumValues: $0.FieldType.values)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sortId')
    ..hasRequiredFields = false
  ;

  DeleteSortPayloadPB._() : super();
  factory DeleteSortPayloadPB({
    $core.String? viewId,
    $core.String? fieldId,
    $0.FieldType? fieldType,
    $core.String? sortId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (fieldType != null) {
      _result.fieldType = fieldType;
    }
    if (sortId != null) {
      _result.sortId = sortId;
    }
    return _result;
  }
  factory DeleteSortPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteSortPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteSortPayloadPB clone() => DeleteSortPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteSortPayloadPB copyWith(void Function(DeleteSortPayloadPB) updates) => super.copyWith((message) => updates(message as DeleteSortPayloadPB)) as DeleteSortPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteSortPayloadPB create() => DeleteSortPayloadPB._();
  DeleteSortPayloadPB createEmptyInstance() => create();
  static $pb.PbList<DeleteSortPayloadPB> createRepeated() => $pb.PbList<DeleteSortPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static DeleteSortPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSortPayloadPB>(create);
  static DeleteSortPayloadPB? _defaultInstance;

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
  $0.FieldType get fieldType => $_getN(2);
  @$pb.TagNumber(3)
  set fieldType($0.FieldType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFieldType() => $_has(2);
  @$pb.TagNumber(3)
  void clearFieldType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get sortId => $_getSZ(3);
  @$pb.TagNumber(4)
  set sortId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSortId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSortId() => clearField(4);
}

class SortChangesetNotificationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SortChangesetNotificationPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..pc<GridSortPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertSorts', $pb.PbFieldType.PM, subBuilder: GridSortPB.create)
    ..pc<GridSortPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteSorts', $pb.PbFieldType.PM, subBuilder: GridSortPB.create)
    ..pc<GridSortPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updateSorts', $pb.PbFieldType.PM, subBuilder: GridSortPB.create)
    ..hasRequiredFields = false
  ;

  SortChangesetNotificationPB._() : super();
  factory SortChangesetNotificationPB({
    $core.String? viewId,
    $core.Iterable<GridSortPB>? insertSorts,
    $core.Iterable<GridSortPB>? deleteSorts,
    $core.Iterable<GridSortPB>? updateSorts,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (insertSorts != null) {
      _result.insertSorts.addAll(insertSorts);
    }
    if (deleteSorts != null) {
      _result.deleteSorts.addAll(deleteSorts);
    }
    if (updateSorts != null) {
      _result.updateSorts.addAll(updateSorts);
    }
    return _result;
  }
  factory SortChangesetNotificationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SortChangesetNotificationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SortChangesetNotificationPB clone() => SortChangesetNotificationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SortChangesetNotificationPB copyWith(void Function(SortChangesetNotificationPB) updates) => super.copyWith((message) => updates(message as SortChangesetNotificationPB)) as SortChangesetNotificationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SortChangesetNotificationPB create() => SortChangesetNotificationPB._();
  SortChangesetNotificationPB createEmptyInstance() => create();
  static $pb.PbList<SortChangesetNotificationPB> createRepeated() => $pb.PbList<SortChangesetNotificationPB>();
  @$core.pragma('dart2js:noInline')
  static SortChangesetNotificationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SortChangesetNotificationPB>(create);
  static SortChangesetNotificationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<GridSortPB> get insertSorts => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<GridSortPB> get deleteSorts => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<GridSortPB> get updateSorts => $_getList(3);
}

class ReorderAllRowsPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ReorderAllRowsPB', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowOrders')
    ..hasRequiredFields = false
  ;

  ReorderAllRowsPB._() : super();
  factory ReorderAllRowsPB({
    $core.Iterable<$core.String>? rowOrders,
  }) {
    final _result = create();
    if (rowOrders != null) {
      _result.rowOrders.addAll(rowOrders);
    }
    return _result;
  }
  factory ReorderAllRowsPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReorderAllRowsPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReorderAllRowsPB clone() => ReorderAllRowsPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReorderAllRowsPB copyWith(void Function(ReorderAllRowsPB) updates) => super.copyWith((message) => updates(message as ReorderAllRowsPB)) as ReorderAllRowsPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReorderAllRowsPB create() => ReorderAllRowsPB._();
  ReorderAllRowsPB createEmptyInstance() => create();
  static $pb.PbList<ReorderAllRowsPB> createRepeated() => $pb.PbList<ReorderAllRowsPB>();
  @$core.pragma('dart2js:noInline')
  static ReorderAllRowsPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReorderAllRowsPB>(create);
  static ReorderAllRowsPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get rowOrders => $_getList(0);
}

class ReorderSingleRowPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ReorderSingleRowPB', createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'oldIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'newIndex', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  ReorderSingleRowPB._() : super();
  factory ReorderSingleRowPB({
    $core.int? oldIndex,
    $core.int? newIndex,
  }) {
    final _result = create();
    if (oldIndex != null) {
      _result.oldIndex = oldIndex;
    }
    if (newIndex != null) {
      _result.newIndex = newIndex;
    }
    return _result;
  }
  factory ReorderSingleRowPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReorderSingleRowPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReorderSingleRowPB clone() => ReorderSingleRowPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReorderSingleRowPB copyWith(void Function(ReorderSingleRowPB) updates) => super.copyWith((message) => updates(message as ReorderSingleRowPB)) as ReorderSingleRowPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReorderSingleRowPB create() => ReorderSingleRowPB._();
  ReorderSingleRowPB createEmptyInstance() => create();
  static $pb.PbList<ReorderSingleRowPB> createRepeated() => $pb.PbList<ReorderSingleRowPB>();
  @$core.pragma('dart2js:noInline')
  static ReorderSingleRowPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReorderSingleRowPB>(create);
  static ReorderSingleRowPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get oldIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set oldIndex($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOldIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearOldIndex() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get newIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set newIndex($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNewIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewIndex() => clearField(2);
}

