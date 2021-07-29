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
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  QueryViewRequest._() : super();
  factory QueryViewRequest({
    $core.String? viewId,
    $core.bool? isTrash,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (isTrash != null) {
      _result.isTrash = isTrash;
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
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isTrash => $_getBF(1);
  @$pb.TagNumber(2)
  set isTrash($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIsTrash() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsTrash() => clearField(2);
}

