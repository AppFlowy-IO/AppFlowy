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
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..hasRequiredFields = false
  ;

  DeleteViewRequest._() : super();
  factory DeleteViewRequest({
    $core.String? viewId,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
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
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);
}

