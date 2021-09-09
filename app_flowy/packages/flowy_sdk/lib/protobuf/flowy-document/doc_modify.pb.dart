///
//  Generated code. Do not modify.
//  source: doc_modify.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum UpdateDocRequest_OneOfData {
  data, 
  notSet
}

class UpdateDocRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateDocRequest_OneOfData> _UpdateDocRequest_OneOfDataByTag = {
    2 : UpdateDocRequest_OneOfData.data,
    0 : UpdateDocRequest_OneOfData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateDocRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  UpdateDocRequest._() : super();
  factory UpdateDocRequest({
    $core.String? id,
    $core.String? data,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory UpdateDocRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateDocRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateDocRequest clone() => UpdateDocRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateDocRequest copyWith(void Function(UpdateDocRequest) updates) => super.copyWith((message) => updates(message as UpdateDocRequest)) as UpdateDocRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateDocRequest create() => UpdateDocRequest._();
  UpdateDocRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateDocRequest> createRepeated() => $pb.PbList<UpdateDocRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateDocRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateDocRequest>(create);
  static UpdateDocRequest? _defaultInstance;

  UpdateDocRequest_OneOfData whichOneOfData() => _UpdateDocRequest_OneOfDataByTag[$_whichOneof(0)]!;
  void clearOneOfData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

enum UpdateDocParams_OneOfData {
  data, 
  notSet
}

class UpdateDocParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateDocParams_OneOfData> _UpdateDocParams_OneOfDataByTag = {
    2 : UpdateDocParams_OneOfData.data,
    0 : UpdateDocParams_OneOfData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateDocParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  UpdateDocParams._() : super();
  factory UpdateDocParams({
    $core.String? id,
    $core.String? data,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory UpdateDocParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateDocParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateDocParams clone() => UpdateDocParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateDocParams copyWith(void Function(UpdateDocParams) updates) => super.copyWith((message) => updates(message as UpdateDocParams)) as UpdateDocParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateDocParams create() => UpdateDocParams._();
  UpdateDocParams createEmptyInstance() => create();
  static $pb.PbList<UpdateDocParams> createRepeated() => $pb.PbList<UpdateDocParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateDocParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateDocParams>(create);
  static UpdateDocParams? _defaultInstance;

  UpdateDocParams_OneOfData whichOneOfData() => _UpdateDocParams_OneOfDataByTag[$_whichOneof(0)]!;
  void clearOneOfData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

