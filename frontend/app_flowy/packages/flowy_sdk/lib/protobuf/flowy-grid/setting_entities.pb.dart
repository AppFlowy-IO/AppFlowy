///
//  Generated code. Do not modify.
//  source: setting_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'util.pb.dart' as $0;
import 'group.pb.dart' as $1;
import 'sort_entities.pb.dart' as $2;

import 'setting_entities.pbenum.dart';

export 'setting_entities.pbenum.dart';

class GridSettingPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridSettingPB', createEmptyInstance: create)
    ..pc<GridLayoutPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'layouts', $pb.PbFieldType.PM, subBuilder: GridLayoutPB.create)
    ..e<GridLayout>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'layoutType', $pb.PbFieldType.OE, defaultOrMaker: GridLayout.Table, valueOf: GridLayout.valueOf, enumValues: GridLayout.values)
    ..aOM<$0.RepeatedFilterPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filters', subBuilder: $0.RepeatedFilterPB.create)
    ..aOM<$1.RepeatedGroupConfigurationPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupConfigurations', subBuilder: $1.RepeatedGroupConfigurationPB.create)
    ..hasRequiredFields = false
  ;

  GridSettingPB._() : super();
  factory GridSettingPB({
    $core.Iterable<GridLayoutPB>? layouts,
    GridLayout? layoutType,
    $0.RepeatedFilterPB? filters,
    $1.RepeatedGroupConfigurationPB? groupConfigurations,
  }) {
    final _result = create();
    if (layouts != null) {
      _result.layouts.addAll(layouts);
    }
    if (layoutType != null) {
      _result.layoutType = layoutType;
    }
    if (filters != null) {
      _result.filters = filters;
    }
    if (groupConfigurations != null) {
      _result.groupConfigurations = groupConfigurations;
    }
    return _result;
  }
  factory GridSettingPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridSettingPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridSettingPB clone() => GridSettingPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridSettingPB copyWith(void Function(GridSettingPB) updates) => super.copyWith((message) => updates(message as GridSettingPB)) as GridSettingPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridSettingPB create() => GridSettingPB._();
  GridSettingPB createEmptyInstance() => create();
  static $pb.PbList<GridSettingPB> createRepeated() => $pb.PbList<GridSettingPB>();
  @$core.pragma('dart2js:noInline')
  static GridSettingPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridSettingPB>(create);
  static GridSettingPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GridLayoutPB> get layouts => $_getList(0);

  @$pb.TagNumber(2)
  GridLayout get layoutType => $_getN(1);
  @$pb.TagNumber(2)
  set layoutType(GridLayout v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLayoutType() => $_has(1);
  @$pb.TagNumber(2)
  void clearLayoutType() => clearField(2);

  @$pb.TagNumber(3)
  $0.RepeatedFilterPB get filters => $_getN(2);
  @$pb.TagNumber(3)
  set filters($0.RepeatedFilterPB v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFilters() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilters() => clearField(3);
  @$pb.TagNumber(3)
  $0.RepeatedFilterPB ensureFilters() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.RepeatedGroupConfigurationPB get groupConfigurations => $_getN(3);
  @$pb.TagNumber(4)
  set groupConfigurations($1.RepeatedGroupConfigurationPB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupConfigurations() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupConfigurations() => clearField(4);
  @$pb.TagNumber(4)
  $1.RepeatedGroupConfigurationPB ensureGroupConfigurations() => $_ensure(3);
}

class GridLayoutPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridLayoutPB', createEmptyInstance: create)
    ..e<GridLayout>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: GridLayout.Table, valueOf: GridLayout.valueOf, enumValues: GridLayout.values)
    ..hasRequiredFields = false
  ;

  GridLayoutPB._() : super();
  factory GridLayoutPB({
    GridLayout? ty,
  }) {
    final _result = create();
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory GridLayoutPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridLayoutPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridLayoutPB clone() => GridLayoutPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridLayoutPB copyWith(void Function(GridLayoutPB) updates) => super.copyWith((message) => updates(message as GridLayoutPB)) as GridLayoutPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridLayoutPB create() => GridLayoutPB._();
  GridLayoutPB createEmptyInstance() => create();
  static $pb.PbList<GridLayoutPB> createRepeated() => $pb.PbList<GridLayoutPB>();
  @$core.pragma('dart2js:noInline')
  static GridLayoutPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridLayoutPB>(create);
  static GridLayoutPB? _defaultInstance;

  @$pb.TagNumber(1)
  GridLayout get ty => $_getN(0);
  @$pb.TagNumber(1)
  set ty(GridLayout v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTy() => $_has(0);
  @$pb.TagNumber(1)
  void clearTy() => clearField(1);
}

enum GridSettingChangesetPB_OneOfAlterFilter {
  alterFilter, 
  notSet
}

enum GridSettingChangesetPB_OneOfDeleteFilter {
  deleteFilter, 
  notSet
}

enum GridSettingChangesetPB_OneOfInsertGroup {
  insertGroup, 
  notSet
}

enum GridSettingChangesetPB_OneOfDeleteGroup {
  deleteGroup, 
  notSet
}

enum GridSettingChangesetPB_OneOfAlterSort {
  alterSort, 
  notSet
}

enum GridSettingChangesetPB_OneOfDeleteSort {
  deleteSort, 
  notSet
}

class GridSettingChangesetPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, GridSettingChangesetPB_OneOfAlterFilter> _GridSettingChangesetPB_OneOfAlterFilterByTag = {
    3 : GridSettingChangesetPB_OneOfAlterFilter.alterFilter,
    0 : GridSettingChangesetPB_OneOfAlterFilter.notSet
  };
  static const $core.Map<$core.int, GridSettingChangesetPB_OneOfDeleteFilter> _GridSettingChangesetPB_OneOfDeleteFilterByTag = {
    4 : GridSettingChangesetPB_OneOfDeleteFilter.deleteFilter,
    0 : GridSettingChangesetPB_OneOfDeleteFilter.notSet
  };
  static const $core.Map<$core.int, GridSettingChangesetPB_OneOfInsertGroup> _GridSettingChangesetPB_OneOfInsertGroupByTag = {
    5 : GridSettingChangesetPB_OneOfInsertGroup.insertGroup,
    0 : GridSettingChangesetPB_OneOfInsertGroup.notSet
  };
  static const $core.Map<$core.int, GridSettingChangesetPB_OneOfDeleteGroup> _GridSettingChangesetPB_OneOfDeleteGroupByTag = {
    6 : GridSettingChangesetPB_OneOfDeleteGroup.deleteGroup,
    0 : GridSettingChangesetPB_OneOfDeleteGroup.notSet
  };
  static const $core.Map<$core.int, GridSettingChangesetPB_OneOfAlterSort> _GridSettingChangesetPB_OneOfAlterSortByTag = {
    7 : GridSettingChangesetPB_OneOfAlterSort.alterSort,
    0 : GridSettingChangesetPB_OneOfAlterSort.notSet
  };
  static const $core.Map<$core.int, GridSettingChangesetPB_OneOfDeleteSort> _GridSettingChangesetPB_OneOfDeleteSortByTag = {
    8 : GridSettingChangesetPB_OneOfDeleteSort.deleteSort,
    0 : GridSettingChangesetPB_OneOfDeleteSort.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridSettingChangesetPB', createEmptyInstance: create)
    ..oo(0, [3])
    ..oo(1, [4])
    ..oo(2, [5])
    ..oo(3, [6])
    ..oo(4, [7])
    ..oo(5, [8])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..e<GridLayout>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'layoutType', $pb.PbFieldType.OE, defaultOrMaker: GridLayout.Table, valueOf: GridLayout.valueOf, enumValues: GridLayout.values)
    ..aOM<$0.AlterFilterPayloadPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'alterFilter', subBuilder: $0.AlterFilterPayloadPB.create)
    ..aOM<$0.DeleteFilterPayloadPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteFilter', subBuilder: $0.DeleteFilterPayloadPB.create)
    ..aOM<$1.InsertGroupPayloadPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertGroup', subBuilder: $1.InsertGroupPayloadPB.create)
    ..aOM<$1.DeleteGroupPayloadPB>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteGroup', subBuilder: $1.DeleteGroupPayloadPB.create)
    ..aOM<$2.AlterSortPayloadPB>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'alterSort', subBuilder: $2.AlterSortPayloadPB.create)
    ..aOM<$2.DeleteSortPayloadPB>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteSort', subBuilder: $2.DeleteSortPayloadPB.create)
    ..hasRequiredFields = false
  ;

  GridSettingChangesetPB._() : super();
  factory GridSettingChangesetPB({
    $core.String? gridId,
    GridLayout? layoutType,
    $0.AlterFilterPayloadPB? alterFilter,
    $0.DeleteFilterPayloadPB? deleteFilter,
    $1.InsertGroupPayloadPB? insertGroup,
    $1.DeleteGroupPayloadPB? deleteGroup,
    $2.AlterSortPayloadPB? alterSort,
    $2.DeleteSortPayloadPB? deleteSort,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (layoutType != null) {
      _result.layoutType = layoutType;
    }
    if (alterFilter != null) {
      _result.alterFilter = alterFilter;
    }
    if (deleteFilter != null) {
      _result.deleteFilter = deleteFilter;
    }
    if (insertGroup != null) {
      _result.insertGroup = insertGroup;
    }
    if (deleteGroup != null) {
      _result.deleteGroup = deleteGroup;
    }
    if (alterSort != null) {
      _result.alterSort = alterSort;
    }
    if (deleteSort != null) {
      _result.deleteSort = deleteSort;
    }
    return _result;
  }
  factory GridSettingChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridSettingChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridSettingChangesetPB clone() => GridSettingChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridSettingChangesetPB copyWith(void Function(GridSettingChangesetPB) updates) => super.copyWith((message) => updates(message as GridSettingChangesetPB)) as GridSettingChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridSettingChangesetPB create() => GridSettingChangesetPB._();
  GridSettingChangesetPB createEmptyInstance() => create();
  static $pb.PbList<GridSettingChangesetPB> createRepeated() => $pb.PbList<GridSettingChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static GridSettingChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridSettingChangesetPB>(create);
  static GridSettingChangesetPB? _defaultInstance;

  GridSettingChangesetPB_OneOfAlterFilter whichOneOfAlterFilter() => _GridSettingChangesetPB_OneOfAlterFilterByTag[$_whichOneof(0)]!;
  void clearOneOfAlterFilter() => clearField($_whichOneof(0));

  GridSettingChangesetPB_OneOfDeleteFilter whichOneOfDeleteFilter() => _GridSettingChangesetPB_OneOfDeleteFilterByTag[$_whichOneof(1)]!;
  void clearOneOfDeleteFilter() => clearField($_whichOneof(1));

  GridSettingChangesetPB_OneOfInsertGroup whichOneOfInsertGroup() => _GridSettingChangesetPB_OneOfInsertGroupByTag[$_whichOneof(2)]!;
  void clearOneOfInsertGroup() => clearField($_whichOneof(2));

  GridSettingChangesetPB_OneOfDeleteGroup whichOneOfDeleteGroup() => _GridSettingChangesetPB_OneOfDeleteGroupByTag[$_whichOneof(3)]!;
  void clearOneOfDeleteGroup() => clearField($_whichOneof(3));

  GridSettingChangesetPB_OneOfAlterSort whichOneOfAlterSort() => _GridSettingChangesetPB_OneOfAlterSortByTag[$_whichOneof(4)]!;
  void clearOneOfAlterSort() => clearField($_whichOneof(4));

  GridSettingChangesetPB_OneOfDeleteSort whichOneOfDeleteSort() => _GridSettingChangesetPB_OneOfDeleteSortByTag[$_whichOneof(5)]!;
  void clearOneOfDeleteSort() => clearField($_whichOneof(5));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  GridLayout get layoutType => $_getN(1);
  @$pb.TagNumber(2)
  set layoutType(GridLayout v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLayoutType() => $_has(1);
  @$pb.TagNumber(2)
  void clearLayoutType() => clearField(2);

  @$pb.TagNumber(3)
  $0.AlterFilterPayloadPB get alterFilter => $_getN(2);
  @$pb.TagNumber(3)
  set alterFilter($0.AlterFilterPayloadPB v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAlterFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlterFilter() => clearField(3);
  @$pb.TagNumber(3)
  $0.AlterFilterPayloadPB ensureAlterFilter() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.DeleteFilterPayloadPB get deleteFilter => $_getN(3);
  @$pb.TagNumber(4)
  set deleteFilter($0.DeleteFilterPayloadPB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeleteFilter() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeleteFilter() => clearField(4);
  @$pb.TagNumber(4)
  $0.DeleteFilterPayloadPB ensureDeleteFilter() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.InsertGroupPayloadPB get insertGroup => $_getN(4);
  @$pb.TagNumber(5)
  set insertGroup($1.InsertGroupPayloadPB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasInsertGroup() => $_has(4);
  @$pb.TagNumber(5)
  void clearInsertGroup() => clearField(5);
  @$pb.TagNumber(5)
  $1.InsertGroupPayloadPB ensureInsertGroup() => $_ensure(4);

  @$pb.TagNumber(6)
  $1.DeleteGroupPayloadPB get deleteGroup => $_getN(5);
  @$pb.TagNumber(6)
  set deleteGroup($1.DeleteGroupPayloadPB v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeleteGroup() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeleteGroup() => clearField(6);
  @$pb.TagNumber(6)
  $1.DeleteGroupPayloadPB ensureDeleteGroup() => $_ensure(5);

  @$pb.TagNumber(7)
  $2.AlterSortPayloadPB get alterSort => $_getN(6);
  @$pb.TagNumber(7)
  set alterSort($2.AlterSortPayloadPB v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasAlterSort() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlterSort() => clearField(7);
  @$pb.TagNumber(7)
  $2.AlterSortPayloadPB ensureAlterSort() => $_ensure(6);

  @$pb.TagNumber(8)
  $2.DeleteSortPayloadPB get deleteSort => $_getN(7);
  @$pb.TagNumber(8)
  set deleteSort($2.DeleteSortPayloadPB v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasDeleteSort() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeleteSort() => clearField(8);
  @$pb.TagNumber(8)
  $2.DeleteSortPayloadPB ensureDeleteSort() => $_ensure(7);
}

