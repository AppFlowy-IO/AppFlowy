import 'package:app_flowy/plugins/grid/application/field/type_option/multi_select_type_option.dart';
import 'package:flutter/material.dart';

import '../field_type_option_editor.dart';
import 'builder.dart';
import 'select_option.dart';

class MultiSelectTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final MultiSelectTypeOptionWidget _widget;

  MultiSelectTypeOptionWidgetBuilder(
    MultiSelectAction typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
  ) : _widget = MultiSelectTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final MultiSelectAction typeOptionContext;
  final TypeOptionOverlayDelegate overlayDelegate;

  const MultiSelectTypeOptionWidget({
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
