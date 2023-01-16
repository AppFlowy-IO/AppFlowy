///
//  Generated code. Do not modify.
//  source: text_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'text_filter.pbenum.dart';

export 'text_filter.pbenum.dart';

class TextFilterPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TextFilterPB', createEmptyInstance: create)
    ..e<TextFilterConditionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: TextFilterConditionPB.Is, valueOf: TextFilterConditionPB.valueOf, enumValues: TextFilterConditionPB.values)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..hasRequiredFields = false
  ;

  TextFilterPB._() : super();
  factory TextFilterPB({
    TextFilterConditionPB? condition,
    $core.String? content,
  }) {
    final _result = create();
    if (condition != null) {
      _result.condition = condition;
    }
    if (content != null) {
      _result.content = content;
    }
    return _result;
  }
  factory TextFilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextFilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextFilterPB clone() => TextFilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextFilterPB copyWith(void Function(TextFilterPB) updates) => super.copyWith((message) => updates(message as TextFilterPB)) as TextFilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TextFilterPB create() => TextFilterPB._();
  TextFilterPB createEmptyInstance() => create();
  static $pb.PbList<TextFilterPB> createRepeated() => $pb.PbList<TextFilterPB>();
  @$core.pragma('dart2js:noInline')
  static TextFilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextFilterPB>(create);
  static TextFilterPB? _defaultInstance;

  @$pb.TagNumber(1)
  TextFilterConditionPB get condition => $_getN(0);
  @$pb.TagNumber(1)
  set condition(TextFilterConditionPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearCondition() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => clearField(2);
}

