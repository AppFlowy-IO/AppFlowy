///
//  Generated code. Do not modify.
//  source: single_select_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'select_type_option.pb.dart' as $0;

class SingleSelectTypeOptionPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SingleSelectTypeOptionPB', createEmptyInstance: create)
    ..pc<$0.SelectOptionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: $0.SelectOptionPB.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  SingleSelectTypeOptionPB._() : super();
  factory SingleSelectTypeOptionPB({
    $core.Iterable<$0.SelectOptionPB>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory SingleSelectTypeOptionPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SingleSelectTypeOptionPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOptionPB clone() => SingleSelectTypeOptionPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOptionPB copyWith(void Function(SingleSelectTypeOptionPB) updates) => super.copyWith((message) => updates(message as SingleSelectTypeOptionPB)) as SingleSelectTypeOptionPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOptionPB create() => SingleSelectTypeOptionPB._();
  SingleSelectTypeOptionPB createEmptyInstance() => create();
  static $pb.PbList<SingleSelectTypeOptionPB> createRepeated() => $pb.PbList<SingleSelectTypeOptionPB>();
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOptionPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SingleSelectTypeOptionPB>(create);
  static SingleSelectTypeOptionPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$0.SelectOptionPB> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

