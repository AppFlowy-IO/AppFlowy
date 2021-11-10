///
//  Generated code. Do not modify.
//  source: workspace_setting.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'workspace_create.pb.dart' as $0;
import 'view_create.pb.dart' as $1;

enum CurrentWorkspaceSetting_OneOfLatestView {
  latestView, 
  notSet
}

class CurrentWorkspaceSetting extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CurrentWorkspaceSetting_OneOfLatestView> _CurrentWorkspaceSetting_OneOfLatestViewByTag = {
    2 : CurrentWorkspaceSetting_OneOfLatestView.latestView,
    0 : CurrentWorkspaceSetting_OneOfLatestView.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CurrentWorkspaceSetting', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOM<$0.Workspace>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspace', subBuilder: $0.Workspace.create)
    ..aOM<$1.View>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'latestView', subBuilder: $1.View.create)
    ..hasRequiredFields = false
  ;

  CurrentWorkspaceSetting._() : super();
  factory CurrentWorkspaceSetting({
    $0.Workspace? workspace,
    $1.View? latestView,
  }) {
    final _result = create();
    if (workspace != null) {
      _result.workspace = workspace;
    }
    if (latestView != null) {
      _result.latestView = latestView;
    }
    return _result;
  }
  factory CurrentWorkspaceSetting.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CurrentWorkspaceSetting.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CurrentWorkspaceSetting clone() => CurrentWorkspaceSetting()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CurrentWorkspaceSetting copyWith(void Function(CurrentWorkspaceSetting) updates) => super.copyWith((message) => updates(message as CurrentWorkspaceSetting)) as CurrentWorkspaceSetting; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CurrentWorkspaceSetting create() => CurrentWorkspaceSetting._();
  CurrentWorkspaceSetting createEmptyInstance() => create();
  static $pb.PbList<CurrentWorkspaceSetting> createRepeated() => $pb.PbList<CurrentWorkspaceSetting>();
  @$core.pragma('dart2js:noInline')
  static CurrentWorkspaceSetting getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CurrentWorkspaceSetting>(create);
  static CurrentWorkspaceSetting? _defaultInstance;

  CurrentWorkspaceSetting_OneOfLatestView whichOneOfLatestView() => _CurrentWorkspaceSetting_OneOfLatestViewByTag[$_whichOneof(0)]!;
  void clearOneOfLatestView() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Workspace get workspace => $_getN(0);
  @$pb.TagNumber(1)
  set workspace($0.Workspace v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspace() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspace() => clearField(1);
  @$pb.TagNumber(1)
  $0.Workspace ensureWorkspace() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.View get latestView => $_getN(1);
  @$pb.TagNumber(2)
  set latestView($1.View v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatestView() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatestView() => clearField(2);
  @$pb.TagNumber(2)
  $1.View ensureLatestView() => $_ensure(1);
}

