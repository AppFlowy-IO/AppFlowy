///
//  Generated code. Do not modify.
//  source: checkbox_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CheckboxTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CheckboxTypeOption', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isSelected')
    ..hasRequiredFields = false
  ;

  CheckboxTypeOption._() : super();
  factory CheckboxTypeOption({
    $core.bool? isSelected,
  }) {
    final _result = create();
    if (isSelected != null) {
      _result.isSelected = isSelected;
    }
    return _result;
  }
  factory CheckboxTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckboxTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckboxTypeOption clone() => CheckboxTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckboxTypeOption copyWith(void Function(CheckboxTypeOption) updates) => super.copyWith((message) => updates(message as CheckboxTypeOption)) as CheckboxTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CheckboxTypeOption create() => CheckboxTypeOption._();
  CheckboxTypeOption createEmptyInstance() => create();
  static $pb.PbList<CheckboxTypeOption> createRepeated() => $pb.PbList<CheckboxTypeOption>();
  @$core.pragma('dart2js:noInline')
  static CheckboxTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckboxTypeOption>(create);
  static CheckboxTypeOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isSelected => $_getBF(0);
  @$pb.TagNumber(1)
  set isSelected($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIsSelected() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsSelected() => clearField(1);
}

