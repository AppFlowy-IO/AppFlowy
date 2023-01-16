///
//  Generated code. Do not modify.
//  source: filter_changeset.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'util.pb.dart' as $0;

class FilterChangesetNotificationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FilterChangesetNotificationPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..pc<$0.FilterPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertFilters', $pb.PbFieldType.PM, subBuilder: $0.FilterPB.create)
    ..pc<$0.FilterPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteFilters', $pb.PbFieldType.PM, subBuilder: $0.FilterPB.create)
    ..pc<UpdatedFilter>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updateFilters', $pb.PbFieldType.PM, subBuilder: UpdatedFilter.create)
    ..hasRequiredFields = false
  ;

  FilterChangesetNotificationPB._() : super();
  factory FilterChangesetNotificationPB({
    $core.String? viewId,
    $core.Iterable<$0.FilterPB>? insertFilters,
    $core.Iterable<$0.FilterPB>? deleteFilters,
    $core.Iterable<UpdatedFilter>? updateFilters,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (insertFilters != null) {
      _result.insertFilters.addAll(insertFilters);
    }
    if (deleteFilters != null) {
      _result.deleteFilters.addAll(deleteFilters);
    }
    if (updateFilters != null) {
      _result.updateFilters.addAll(updateFilters);
    }
    return _result;
  }
  factory FilterChangesetNotificationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FilterChangesetNotificationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FilterChangesetNotificationPB clone() => FilterChangesetNotificationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FilterChangesetNotificationPB copyWith(void Function(FilterChangesetNotificationPB) updates) => super.copyWith((message) => updates(message as FilterChangesetNotificationPB)) as FilterChangesetNotificationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FilterChangesetNotificationPB create() => FilterChangesetNotificationPB._();
  FilterChangesetNotificationPB createEmptyInstance() => create();
  static $pb.PbList<FilterChangesetNotificationPB> createRepeated() => $pb.PbList<FilterChangesetNotificationPB>();
  @$core.pragma('dart2js:noInline')
  static FilterChangesetNotificationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FilterChangesetNotificationPB>(create);
  static FilterChangesetNotificationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$0.FilterPB> get insertFilters => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$0.FilterPB> get deleteFilters => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<UpdatedFilter> get updateFilters => $_getList(3);
}

enum UpdatedFilter_OneOfFilter {
  filter, 
  notSet
}

class UpdatedFilter extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdatedFilter_OneOfFilter> _UpdatedFilter_OneOfFilterByTag = {
    2 : UpdatedFilter_OneOfFilter.filter,
    0 : UpdatedFilter_OneOfFilter.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdatedFilter', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filterId')
    ..aOM<$0.FilterPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filter', subBuilder: $0.FilterPB.create)
    ..hasRequiredFields = false
  ;

  UpdatedFilter._() : super();
  factory UpdatedFilter({
    $core.String? filterId,
    $0.FilterPB? filter,
  }) {
    final _result = create();
    if (filterId != null) {
      _result.filterId = filterId;
    }
    if (filter != null) {
      _result.filter = filter;
    }
    return _result;
  }
  factory UpdatedFilter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdatedFilter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdatedFilter clone() => UpdatedFilter()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdatedFilter copyWith(void Function(UpdatedFilter) updates) => super.copyWith((message) => updates(message as UpdatedFilter)) as UpdatedFilter; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdatedFilter create() => UpdatedFilter._();
  UpdatedFilter createEmptyInstance() => create();
  static $pb.PbList<UpdatedFilter> createRepeated() => $pb.PbList<UpdatedFilter>();
  @$core.pragma('dart2js:noInline')
  static UpdatedFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdatedFilter>(create);
  static UpdatedFilter? _defaultInstance;

  UpdatedFilter_OneOfFilter whichOneOfFilter() => _UpdatedFilter_OneOfFilterByTag[$_whichOneof(0)]!;
  void clearOneOfFilter() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get filterId => $_getSZ(0);
  @$pb.TagNumber(1)
  set filterId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFilterId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilterId() => clearField(1);

  @$pb.TagNumber(2)
  $0.FilterPB get filter => $_getN(1);
  @$pb.TagNumber(2)
  set filter($0.FilterPB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFilter() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilter() => clearField(2);
  @$pb.TagNumber(2)
  $0.FilterPB ensureFilter() => $_ensure(1);
}

