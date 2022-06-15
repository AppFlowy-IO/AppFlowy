///
//  Generated code. Do not modify.
//  source: view_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'view.pb.dart' as $0;

import 'view.pbenum.dart' as $0;

class ViewInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewInfo', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<$0.ViewDataType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: $0.ViewDataType.TextBlock, valueOf: $0.ViewDataType.valueOf, enumValues: $0.ViewDataType.values)
    ..aOM<$0.RepeatedView>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: $0.RepeatedView.create)
    ..aOM<ViewExtData>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extData', subBuilder: ViewExtData.create)
    ..hasRequiredFields = false
  ;

  ViewInfo._() : super();
  factory ViewInfo({
    $core.String? id,
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $0.ViewDataType? dataType,
    $0.RepeatedView? belongings,
    ViewExtData? extData,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (belongToId != null) {
      _result.belongToId = belongToId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (belongings != null) {
      _result.belongings = belongings;
    }
    if (extData != null) {
      _result.extData = extData;
    }
    return _result;
  }
  factory ViewInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewInfo clone() => ViewInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewInfo copyWith(void Function(ViewInfo) updates) => super.copyWith((message) => updates(message as ViewInfo)) as ViewInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewInfo create() => ViewInfo._();
  ViewInfo createEmptyInstance() => create();
  static $pb.PbList<ViewInfo> createRepeated() => $pb.PbList<ViewInfo>();
  @$core.pragma('dart2js:noInline')
  static ViewInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewInfo>(create);
  static ViewInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get belongToId => $_getSZ(1);
  @$pb.TagNumber(2)
  set belongToId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBelongToId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBelongToId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get desc => $_getSZ(3);
  @$pb.TagNumber(4)
  set desc($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDesc() => $_has(3);
  @$pb.TagNumber(4)
  void clearDesc() => clearField(4);

  @$pb.TagNumber(5)
  $0.ViewDataType get dataType => $_getN(4);
  @$pb.TagNumber(5)
  set dataType($0.ViewDataType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDataType() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataType() => clearField(5);

  @$pb.TagNumber(6)
  $0.RepeatedView get belongings => $_getN(5);
  @$pb.TagNumber(6)
  set belongings($0.RepeatedView v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBelongings() => $_has(5);
  @$pb.TagNumber(6)
  void clearBelongings() => clearField(6);
  @$pb.TagNumber(6)
  $0.RepeatedView ensureBelongings() => $_ensure(5);

  @$pb.TagNumber(7)
  ViewExtData get extData => $_getN(6);
  @$pb.TagNumber(7)
  set extData(ViewExtData v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasExtData() => $_has(6);
  @$pb.TagNumber(7)
  void clearExtData() => clearField(7);
  @$pb.TagNumber(7)
  ViewExtData ensureExtData() => $_ensure(6);
}

class ViewExtData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewExtData', createEmptyInstance: create)
    ..aOM<ViewFilter>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filter', subBuilder: ViewFilter.create)
    ..aOM<ViewGroup>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'group', subBuilder: ViewGroup.create)
    ..aOM<ViewSort>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sort', subBuilder: ViewSort.create)
    ..hasRequiredFields = false
  ;

  ViewExtData._() : super();
  factory ViewExtData({
    ViewFilter? filter,
    ViewGroup? group,
    ViewSort? sort,
  }) {
    final _result = create();
    if (filter != null) {
      _result.filter = filter;
    }
    if (group != null) {
      _result.group = group;
    }
    if (sort != null) {
      _result.sort = sort;
    }
    return _result;
  }
  factory ViewExtData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewExtData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewExtData clone() => ViewExtData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewExtData copyWith(void Function(ViewExtData) updates) => super.copyWith((message) => updates(message as ViewExtData)) as ViewExtData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewExtData create() => ViewExtData._();
  ViewExtData createEmptyInstance() => create();
  static $pb.PbList<ViewExtData> createRepeated() => $pb.PbList<ViewExtData>();
  @$core.pragma('dart2js:noInline')
  static ViewExtData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewExtData>(create);
  static ViewExtData? _defaultInstance;

  @$pb.TagNumber(1)
  ViewFilter get filter => $_getN(0);
  @$pb.TagNumber(1)
  set filter(ViewFilter v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFilter() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilter() => clearField(1);
  @$pb.TagNumber(1)
  ViewFilter ensureFilter() => $_ensure(0);

  @$pb.TagNumber(2)
  ViewGroup get group => $_getN(1);
  @$pb.TagNumber(2)
  set group(ViewGroup v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroup() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroup() => clearField(2);
  @$pb.TagNumber(2)
  ViewGroup ensureGroup() => $_ensure(1);

  @$pb.TagNumber(3)
  ViewSort get sort => $_getN(2);
  @$pb.TagNumber(3)
  set sort(ViewSort v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSort() => $_has(2);
  @$pb.TagNumber(3)
  void clearSort() => clearField(3);
  @$pb.TagNumber(3)
  ViewSort ensureSort() => $_ensure(2);
}

class ViewFilter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewFilter', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'objectId')
    ..hasRequiredFields = false
  ;

  ViewFilter._() : super();
  factory ViewFilter({
    $core.String? objectId,
  }) {
    final _result = create();
    if (objectId != null) {
      _result.objectId = objectId;
    }
    return _result;
  }
  factory ViewFilter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewFilter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewFilter clone() => ViewFilter()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewFilter copyWith(void Function(ViewFilter) updates) => super.copyWith((message) => updates(message as ViewFilter)) as ViewFilter; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewFilter create() => ViewFilter._();
  ViewFilter createEmptyInstance() => create();
  static $pb.PbList<ViewFilter> createRepeated() => $pb.PbList<ViewFilter>();
  @$core.pragma('dart2js:noInline')
  static ViewFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewFilter>(create);
  static ViewFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set objectId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasObjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjectId() => clearField(1);
}

enum ViewGroup_OneOfSubGroupObjectId {
  subGroupObjectId, 
  notSet
}

class ViewGroup extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ViewGroup_OneOfSubGroupObjectId> _ViewGroup_OneOfSubGroupObjectIdByTag = {
    2 : ViewGroup_OneOfSubGroupObjectId.subGroupObjectId,
    0 : ViewGroup_OneOfSubGroupObjectId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewGroup', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupObjectId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subGroupObjectId')
    ..hasRequiredFields = false
  ;

  ViewGroup._() : super();
  factory ViewGroup({
    $core.String? groupObjectId,
    $core.String? subGroupObjectId,
  }) {
    final _result = create();
    if (groupObjectId != null) {
      _result.groupObjectId = groupObjectId;
    }
    if (subGroupObjectId != null) {
      _result.subGroupObjectId = subGroupObjectId;
    }
    return _result;
  }
  factory ViewGroup.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewGroup.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewGroup clone() => ViewGroup()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewGroup copyWith(void Function(ViewGroup) updates) => super.copyWith((message) => updates(message as ViewGroup)) as ViewGroup; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewGroup create() => ViewGroup._();
  ViewGroup createEmptyInstance() => create();
  static $pb.PbList<ViewGroup> createRepeated() => $pb.PbList<ViewGroup>();
  @$core.pragma('dart2js:noInline')
  static ViewGroup getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewGroup>(create);
  static ViewGroup? _defaultInstance;

  ViewGroup_OneOfSubGroupObjectId whichOneOfSubGroupObjectId() => _ViewGroup_OneOfSubGroupObjectIdByTag[$_whichOneof(0)]!;
  void clearOneOfSubGroupObjectId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get groupObjectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupObjectId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupObjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupObjectId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get subGroupObjectId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subGroupObjectId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSubGroupObjectId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubGroupObjectId() => clearField(2);
}

class ViewSort extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewSort', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'objectId')
    ..hasRequiredFields = false
  ;

  ViewSort._() : super();
  factory ViewSort({
    $core.String? objectId,
  }) {
    final _result = create();
    if (objectId != null) {
      _result.objectId = objectId;
    }
    return _result;
  }
  factory ViewSort.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewSort.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewSort clone() => ViewSort()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewSort copyWith(void Function(ViewSort) updates) => super.copyWith((message) => updates(message as ViewSort)) as ViewSort; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewSort create() => ViewSort._();
  ViewSort createEmptyInstance() => create();
  static $pb.PbList<ViewSort> createRepeated() => $pb.PbList<ViewSort>();
  @$core.pragma('dart2js:noInline')
  static ViewSort getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewSort>(create);
  static ViewSort? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set objectId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasObjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjectId() => clearField(1);
}

enum UpdateViewInfoPayload_OneOfFilter {
  filter, 
  notSet
}

enum UpdateViewInfoPayload_OneOfGroup {
  group, 
  notSet
}

enum UpdateViewInfoPayload_OneOfSort {
  sort, 
  notSet
}

class UpdateViewInfoPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateViewInfoPayload_OneOfFilter> _UpdateViewInfoPayload_OneOfFilterByTag = {
    2 : UpdateViewInfoPayload_OneOfFilter.filter,
    0 : UpdateViewInfoPayload_OneOfFilter.notSet
  };
  static const $core.Map<$core.int, UpdateViewInfoPayload_OneOfGroup> _UpdateViewInfoPayload_OneOfGroupByTag = {
    3 : UpdateViewInfoPayload_OneOfGroup.group,
    0 : UpdateViewInfoPayload_OneOfGroup.notSet
  };
  static const $core.Map<$core.int, UpdateViewInfoPayload_OneOfSort> _UpdateViewInfoPayload_OneOfSortByTag = {
    4 : UpdateViewInfoPayload_OneOfSort.sort,
    0 : UpdateViewInfoPayload_OneOfSort.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateViewInfoPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOM<ViewFilter>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filter', subBuilder: ViewFilter.create)
    ..aOM<ViewGroup>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'group', subBuilder: ViewGroup.create)
    ..aOM<ViewSort>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sort', subBuilder: ViewSort.create)
    ..hasRequiredFields = false
  ;

  UpdateViewInfoPayload._() : super();
  factory UpdateViewInfoPayload({
    $core.String? viewId,
    ViewFilter? filter,
    ViewGroup? group,
    ViewSort? sort,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (filter != null) {
      _result.filter = filter;
    }
    if (group != null) {
      _result.group = group;
    }
    if (sort != null) {
      _result.sort = sort;
    }
    return _result;
  }
  factory UpdateViewInfoPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateViewInfoPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateViewInfoPayload clone() => UpdateViewInfoPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateViewInfoPayload copyWith(void Function(UpdateViewInfoPayload) updates) => super.copyWith((message) => updates(message as UpdateViewInfoPayload)) as UpdateViewInfoPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateViewInfoPayload create() => UpdateViewInfoPayload._();
  UpdateViewInfoPayload createEmptyInstance() => create();
  static $pb.PbList<UpdateViewInfoPayload> createRepeated() => $pb.PbList<UpdateViewInfoPayload>();
  @$core.pragma('dart2js:noInline')
  static UpdateViewInfoPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateViewInfoPayload>(create);
  static UpdateViewInfoPayload? _defaultInstance;

  UpdateViewInfoPayload_OneOfFilter whichOneOfFilter() => _UpdateViewInfoPayload_OneOfFilterByTag[$_whichOneof(0)]!;
  void clearOneOfFilter() => clearField($_whichOneof(0));

  UpdateViewInfoPayload_OneOfGroup whichOneOfGroup() => _UpdateViewInfoPayload_OneOfGroupByTag[$_whichOneof(1)]!;
  void clearOneOfGroup() => clearField($_whichOneof(1));

  UpdateViewInfoPayload_OneOfSort whichOneOfSort() => _UpdateViewInfoPayload_OneOfSortByTag[$_whichOneof(2)]!;
  void clearOneOfSort() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  ViewFilter get filter => $_getN(1);
  @$pb.TagNumber(2)
  set filter(ViewFilter v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFilter() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilter() => clearField(2);
  @$pb.TagNumber(2)
  ViewFilter ensureFilter() => $_ensure(1);

  @$pb.TagNumber(3)
  ViewGroup get group => $_getN(2);
  @$pb.TagNumber(3)
  set group(ViewGroup v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroup() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroup() => clearField(3);
  @$pb.TagNumber(3)
  ViewGroup ensureGroup() => $_ensure(2);

  @$pb.TagNumber(4)
  ViewSort get sort => $_getN(3);
  @$pb.TagNumber(4)
  set sort(ViewSort v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSort() => $_has(3);
  @$pb.TagNumber(4)
  void clearSort() => clearField(4);
  @$pb.TagNumber(4)
  ViewSort ensureSort() => $_ensure(3);
}

