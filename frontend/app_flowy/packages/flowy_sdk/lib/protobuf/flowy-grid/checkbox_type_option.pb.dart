///
//  Generated code. Do not modify.
//  source: checkbox_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CheckboxTypeOptionPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CheckboxTypeOptionPB', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isSelected')
    ..hasRequiredFields = false
  ;

  CheckboxTypeOptionPB._() : super();
  factory CheckboxTypeOptionPB({
    $core.bool? isSelected,
  }) {
    final _result = create();
    if (isSelected != null) {
      _result.isSelected = isSelected;
    }
    return _result;
  }
  factory CheckboxTypeOptionPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckboxTypeOptionPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckboxTypeOptionPB clone() => CheckboxTypeOptionPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckboxTypeOptionPB copyWith(void Function(CheckboxTypeOptionPB) updates) => super.copyWith((message) => updates(message as CheckboxTypeOptionPB)) as CheckboxTypeOptionPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CheckboxTypeOptionPB create() => CheckboxTypeOptionPB._();
  CheckboxTypeOptionPB createEmptyInstance() => create();
  static $pb.PbList<CheckboxTypeOptionPB> createRepeated() => $pb.PbList<CheckboxTypeOptionPB>();
  @$core.pragma('dart2js:noInline')
  static CheckboxTypeOptionPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckboxTypeOptionPB>(create);
  static CheckboxTypeOptionPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isSelected => $_getBF(0);
  @$pb.TagNumber(1)
  set isSelected($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIsSelected() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsSelected() => clearField(1);
}

