import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocProvider(
      create: (context) => MultiSelectTypeOptionBloc(typeOptionContext),
      child: BlocConsumer<MultiSelectTypeOptionBloc, MultiSelectTypeOptionState>(
        listener: (context, state) {
          typeOptionContext.typeOption = state.typeOption;
        },
        builder: (context, state) {
          return SelectOptionTypeOptionWidget(
            options: state.typeOption.options,
            beginEdit: () {
              overlayDelegate.hideOverlay(context);
            },
            createSelectOptionCallback: (name) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.createOption(name));
            },
            updateSelectOptionCallback: (option) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.updateOption(option));
            },
            deleteSelectOptionCallback: (option) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.deleteOption(option));
            },
            overlayDelegate: overlayDelegate,
            // key: ValueKey(state.typeOption.hashCode),
          );
        },
      ),
    );
  }
}
