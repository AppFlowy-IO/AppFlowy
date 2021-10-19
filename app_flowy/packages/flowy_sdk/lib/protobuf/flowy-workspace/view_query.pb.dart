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

class ViewIdentifier extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewIdentifier', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..hasRequiredFields = false
  ;

  ViewIdentifier._() : super();
  factory ViewIdentifier({
    $core.String? viewId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    return _result;
  }
  factory ViewIdentifier.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewIdentifier.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewIdentifier clone() => ViewIdentifier()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewIdentifier copyWith(void Function(ViewIdentifier) updates) => super.copyWith((message) => updates(message as ViewIdentifier)) as ViewIdentifier; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewIdentifier create() => ViewIdentifier._();
  ViewIdentifier createEmptyInstance() => create();
  static $pb.PbList<ViewIdentifier> createRepeated() => $pb.PbList<ViewIdentifier>();
  @$core.pragma('dart2js:noInline')
  static ViewIdentifier getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewIdentifier>(create);
  static ViewIdentifier? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);
}

class ViewIdentifiers extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewIdentifiers', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewIds')
    ..hasRequiredFields = false
  ;

  ViewIdentifiers._() : super();
  factory ViewIdentifiers({
    $core.Iterable<$core.String>? viewIds,
  }) {
    final _result = create();
    if (viewIds != null) {
      _result.viewIds.addAll(viewIds);
    }
    return _result;
  }
  factory ViewIdentifiers.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewIdentifiers.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewIdentifiers clone() => ViewIdentifiers()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewIdentifiers copyWith(void Function(ViewIdentifiers) updates) => super.copyWith((message) => updates(message as ViewIdentifiers)) as ViewIdentifiers; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewIdentifiers create() => ViewIdentifiers._();
  ViewIdentifiers createEmptyInstance() => create();
  static $pb.PbList<ViewIdentifiers> createRepeated() => $pb.PbList<ViewIdentifiers>();
  @$core.pragma('dart2js:noInline')
  static ViewIdentifiers getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewIdentifiers>(create);
  static ViewIdentifiers? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get viewIds => $_getList(0);
}

