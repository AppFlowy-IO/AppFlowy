import 'package:app_flowy/workspace/application/grid/field/type_option/single_select_type_option.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flutter/material.dart';
import 'select_option.dart';

class SingleSelectTypeOptionBuilder extends TypeOptionBuilder {
  final SingleSelectTypeOptionWidget _widget;

  SingleSelectTypeOptionBuilder(
    SingleSelectTypeOptionContext typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
  ) : _widget = SingleSelectTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? get customWidget => _widget;
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
