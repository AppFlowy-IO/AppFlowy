///
//  Generated code. Do not modify.
//  source: view_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class QueryViewRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryViewRequest', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewIds')
    ..hasRequiredFields = false
  ;

  QueryViewRequest._() : super();
  factory QueryViewRequest({
    $core.Iterable<$core.String>? viewIds,
  }) {
    final _result = create();
    if (viewIds != null) {
      _result.viewIds.addAll(viewIds);
    }
    return _result;
  }
  factory QueryViewRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryViewRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryViewRequest clone() => QueryViewRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryViewRequest copyWith(void Function(QueryViewRequest) updates) => super.copyWith((message) => updates(message as QueryViewRequest)) as QueryViewRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryViewRequest create() => QueryViewRequest._();
  QueryViewRequest createEmptyInstance() => create();
  static $pb.PbList<QueryViewRequest> createRepeated() => $pb.PbList<QueryViewRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryViewRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryViewRequest>(create);
  static QueryViewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get viewIds => $_getList(0);
}

class ViewId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..hasRequiredFields = false
  ;

  ViewId._() : super();
  factory ViewId({
    $core.String? viewId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    return _result;
  }
  factory ViewId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewId clone() => ViewId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewId copyWith(void Function(ViewId) updates) => super.copyWith((message) => updates(message as ViewId)) as ViewId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewId create() => ViewId._();
  ViewId createEmptyInstance() => create();
  static $pb.PbList<ViewId> createRepeated() => $pb.PbList<ViewId>();
  @$core.pragma('dart2js:noInline')
  static ViewId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewId>(create);
  static ViewId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);
}

class RepeatedViewId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedViewId', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items')
    ..hasRequiredFields = false
  ;

  RepeatedViewId._() : super();
  factory RepeatedViewId({
    $core.Iterable<$core.String>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedViewId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedViewId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedViewId clone() => RepeatedViewId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedViewId copyWith(void Function(RepeatedViewId) updates) => super.copyWith((message) => updates(message as RepeatedViewId)) as RepeatedViewId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedViewId create() => RepeatedViewId._();
  RepeatedViewId createEmptyInstance() => create();
  static $pb.PbList<RepeatedViewId> createRepeated() => $pb.PbList<RepeatedViewId>();
  @$core.pragma('dart2js:noInline')
  static RepeatedViewId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedViewId>(create);
  static RepeatedViewId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get items => $_getList(0);
}

