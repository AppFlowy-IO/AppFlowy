///
//  Generated code. Do not modify.
//  source: view_delete.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DeleteViewRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteViewRequest', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewIds')
    ..hasRequiredFields = false
  ;

  DeleteViewRequest._() : super();
  factory DeleteViewRequest({
    $core.Iterable<$core.String>? viewIds,
  }) {
    final _result = create();
    if (viewIds != null) {
      _result.viewIds.addAll(viewIds);
    }
    return _result;
  }
  factory DeleteViewRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteViewRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteViewRequest clone() => DeleteViewRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteViewRequest copyWith(void Function(DeleteViewRequest) updates) => super.copyWith((message) => updates(message as DeleteViewRequest)) as DeleteViewRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteViewRequest create() => DeleteViewRequest._();
  DeleteViewRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteViewRequest> createRepeated() => $pb.PbList<DeleteViewRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteViewRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteViewRequest>(create);
  static DeleteViewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get viewIds => $_getList(0);
}

class DeleteViewParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteViewParams', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewIds')
    ..hasRequiredFields = false
  ;

  DeleteViewParams._() : super();
  factory DeleteViewParams({
    $core.Iterable<$core.String>? viewIds,
  }) {
    final _result = create();
    if (viewIds != null) {
      _result.viewIds.addAll(viewIds);
    }
    return _result;
  }
  factory DeleteViewParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteViewParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteViewParams clone() => DeleteViewParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteViewParams copyWith(void Function(DeleteViewParams) updates) => super.copyWith((message) => updates(message as DeleteViewParams)) as DeleteViewParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteViewParams create() => DeleteViewParams._();
  DeleteViewParams createEmptyInstance() => create();
  static $pb.PbList<DeleteViewParams> createRepeated() => $pb.PbList<DeleteViewParams>();
  @$core.pragma('dart2js:noInline')
  static DeleteViewParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteViewParams>(create);
  static DeleteViewParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get viewIds => $_getList(0);
}

