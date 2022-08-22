import 'package:app_flowy/plugins/grid/application/field/type_option/single_select_type_option.dart';
import 'package:flutter/material.dart';
import '../field_type_option_editor.dart';
import 'builder.dart';
import 'select_option.dart';

class SingleSelectTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final SingleSelectTypeOptionWidget _widget;

  SingleSelectTypeOptionWidgetBuilder(
    SingleSelectTypeOptionContext typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
  ) : _widget = SingleSelectTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  final SingleSelectTypeOptionContext typeOptionContext;
  final TypeOptionOverlayDelegate overlayDelegate;

  const SingleSelectTypeOptionWidget({
    required this.typeOptionContext,
    required this.overlayDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectOptionTypeOptionWidget(
      options: typeOptionContext.typeOption.options,
      beginEdit: () => overlayDelegate.hideOverlay(context),
      overlayDelegate: overlayDelegate,
      typeOptionAction: typeOptionContext,
      // key: ValueKey(state.typeOption.hashCode),
    );
  }
}
