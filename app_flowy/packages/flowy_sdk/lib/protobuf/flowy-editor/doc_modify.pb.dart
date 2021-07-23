///
//  Generated code. Do not modify.
//  source: doc_modify.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum UpdateDocRequest_OneOfName {
  name, 
  notSet
}

enum UpdateDocRequest_OneOfDesc {
  desc, 
  notSet
}

enum UpdateDocRequest_OneOfText {
  text, 
  notSet
}

class UpdateDocRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateDocRequest_OneOfName> _UpdateDocRequest_OneOfNameByTag = {
    2 : UpdateDocRequest_OneOfName.name,
    0 : UpdateDocRequest_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateDocRequest_OneOfDesc> _UpdateDocRequest_OneOfDescByTag = {
    3 : UpdateDocRequest_OneOfDesc.desc,
    0 : UpdateDocRequest_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateDocRequest_OneOfText> _UpdateDocRequest_OneOfTextByTag = {
    4 : UpdateDocRequest_OneOfText.text,
    0 : UpdateDocRequest_OneOfText.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateDocRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'text')
    ..hasRequiredFields = false
  ;

  UpdateDocRequest._() : super();
  factory UpdateDocRequest({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
    $core.String? text,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (text != null) {
      _result.text = text;
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

  UpdateDocRequest_OneOfName whichOneOfName() => _UpdateDocRequest_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateDocRequest_OneOfDesc whichOneOfDesc() => _UpdateDocRequest_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateDocRequest_OneOfText whichOneOfText() => _UpdateDocRequest_OneOfTextByTag[$_whichOneof(2)]!;
  void clearOneOfText() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => clearField(4);
}

