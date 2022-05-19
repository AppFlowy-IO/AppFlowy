import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_type_option.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flutter/material.dart';

import 'select_option.dart';

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  final MultiSelectTypeOptionWidget _widget;

  MultiSelectTypeOptionBuilder(
    MultiSelectTypeOptionContext typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
  ) : _widget = MultiSelectTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final MultiSelectTypeOptionContext typeOptionContext;
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
