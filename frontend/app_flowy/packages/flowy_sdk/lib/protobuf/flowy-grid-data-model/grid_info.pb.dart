///
//  Generated code. Do not modify.
//  source: grid_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

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

enum ViewFilter_OneOfFieldId {
  fieldId, 
  notSet
}

class ViewFilter extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ViewFilter_OneOfFieldId> _ViewFilter_OneOfFieldIdByTag = {
    1 : ViewFilter_OneOfFieldId.fieldId,
    0 : ViewFilter_OneOfFieldId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewFilter', createEmptyInstance: create)
    ..oo(0, [1])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  ViewFilter._() : super();
  factory ViewFilter({
    $core.String? fieldId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
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

  ViewFilter_OneOfFieldId whichOneOfFieldId() => _ViewFilter_OneOfFieldIdByTag[$_whichOneof(0)]!;
  void clearOneOfFieldId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);
}

enum ViewGroup_OneOfGroupFieldId {
  groupFieldId, 
  notSet
}

enum ViewGroup_OneOfSubGroupFieldId {
  subGroupFieldId, 
  notSet
}

class ViewGroup extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ViewGroup_OneOfGroupFieldId> _ViewGroup_OneOfGroupFieldIdByTag = {
    1 : ViewGroup_OneOfGroupFieldId.groupFieldId,
    0 : ViewGroup_OneOfGroupFieldId.notSet
  };
  static const $core.Map<$core.int, ViewGroup_OneOfSubGroupFieldId> _ViewGroup_OneOfSubGroupFieldIdByTag = {
    2 : ViewGroup_OneOfSubGroupFieldId.subGroupFieldId,
    0 : ViewGroup_OneOfSubGroupFieldId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewGroup', createEmptyInstance: create)
    ..oo(0, [1])
    ..oo(1, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupFieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subGroupFieldId')
    ..hasRequiredFields = false
  ;

  ViewGroup._() : super();
  factory ViewGroup({
    $core.String? groupFieldId,
    $core.String? subGroupFieldId,
  }) {
    final _result = create();
    if (groupFieldId != null) {
      _result.groupFieldId = groupFieldId;
    }
    if (subGroupFieldId != null) {
      _result.subGroupFieldId = subGroupFieldId;
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

  ViewGroup_OneOfGroupFieldId whichOneOfGroupFieldId() => _ViewGroup_OneOfGroupFieldIdByTag[$_whichOneof(0)]!;
  void clearOneOfGroupFieldId() => clearField($_whichOneof(0));

  ViewGroup_OneOfSubGroupFieldId whichOneOfSubGroupFieldId() => _ViewGroup_OneOfSubGroupFieldIdByTag[$_whichOneof(1)]!;
  void clearOneOfSubGroupFieldId() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get groupFieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupFieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get subGroupFieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subGroupFieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSubGroupFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubGroupFieldId() => clearField(2);
}

enum ViewSort_OneOfFieldId {
  fieldId, 
  notSet
}

class ViewSort extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ViewSort_OneOfFieldId> _ViewSort_OneOfFieldIdByTag = {
    1 : ViewSort_OneOfFieldId.fieldId,
    0 : ViewSort_OneOfFieldId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewSort', createEmptyInstance: create)
    ..oo(0, [1])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  ViewSort._() : super();
  factory ViewSort({
    $core.String? fieldId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
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

  ViewSort_OneOfFieldId whichOneOfFieldId() => _ViewSort_OneOfFieldIdByTag[$_whichOneof(0)]!;
  void clearOneOfFieldId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);
}

enum GridInfoChangesetPayload_OneOfFilter {
  filter, 
  notSet
}

enum GridInfoChangesetPayload_OneOfGroup {
  group, 
  notSet
}

enum GridInfoChangesetPayload_OneOfSort {
  sort, 
  notSet
}

class GridInfoChangesetPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, GridInfoChangesetPayload_OneOfFilter> _GridInfoChangesetPayload_OneOfFilterByTag = {
    2 : GridInfoChangesetPayload_OneOfFilter.filter,
    0 : GridInfoChangesetPayload_OneOfFilter.notSet
  };
  static const $core.Map<$core.int, GridInfoChangesetPayload_OneOfGroup> _GridInfoChangesetPayload_OneOfGroupByTag = {
    3 : GridInfoChangesetPayload_OneOfGroup.group,
    0 : GridInfoChangesetPayload_OneOfGroup.notSet
  };
  static const $core.Map<$core.int, GridInfoChangesetPayload_OneOfSort> _GridInfoChangesetPayload_OneOfSortByTag = {
    4 : GridInfoChangesetPayload_OneOfSort.sort,
    0 : GridInfoChangesetPayload_OneOfSort.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridInfoChangesetPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOM<ViewFilter>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filter', subBuilder: ViewFilter.create)
    ..aOM<ViewGroup>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'group', subBuilder: ViewGroup.create)
    ..aOM<ViewSort>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sort', subBuilder: ViewSort.create)
    ..hasRequiredFields = false
  ;

  GridInfoChangesetPayload._() : super();
  factory GridInfoChangesetPayload({
    $core.String? gridId,
    ViewFilter? filter,
    ViewGroup? group,
    ViewSort? sort,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
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
  factory GridInfoChangesetPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridInfoChangesetPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridInfoChangesetPayload clone() => GridInfoChangesetPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridInfoChangesetPayload copyWith(void Function(GridInfoChangesetPayload) updates) => super.copyWith((message) => updates(message as GridInfoChangesetPayload)) as GridInfoChangesetPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridInfoChangesetPayload create() => GridInfoChangesetPayload._();
  GridInfoChangesetPayload createEmptyInstance() => create();
  static $pb.PbList<GridInfoChangesetPayload> createRepeated() => $pb.PbList<GridInfoChangesetPayload>();
  @$core.pragma('dart2js:noInline')
  static GridInfoChangesetPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridInfoChangesetPayload>(create);
  static GridInfoChangesetPayload? _defaultInstance;

  GridInfoChangesetPayload_OneOfFilter whichOneOfFilter() => _GridInfoChangesetPayload_OneOfFilterByTag[$_whichOneof(0)]!;
  void clearOneOfFilter() => clearField($_whichOneof(0));

  GridInfoChangesetPayload_OneOfGroup whichOneOfGroup() => _GridInfoChangesetPayload_OneOfGroupByTag[$_whichOneof(1)]!;
  void clearOneOfGroup() => clearField($_whichOneof(1));

  GridInfoChangesetPayload_OneOfSort whichOneOfSort() => _GridInfoChangesetPayload_OneOfSortByTag[$_whichOneof(2)]!;
  void clearOneOfSort() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

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

