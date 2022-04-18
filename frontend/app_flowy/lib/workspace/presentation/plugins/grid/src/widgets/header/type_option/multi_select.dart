import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_option_pannel.dart';

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  final MultiSelectTypeOptionWidget _widget;

  MultiSelectTypeOptionBuilder(
    TypeOptionContext typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
    TypeOptionDataDelegate dataDelegate,
  ) : _widget = MultiSelectTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          overlayDelegate: overlayDelegate,
          dataDelegate: dataDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final TypeOptionContext typeOptionContext;
  final TypeOptionOverlayDelegate overlayDelegate;
  final TypeOptionDataDelegate dataDelegate;
  const MultiSelectTypeOptionWidget({
    required this.typeOptionContext,
    required this.overlayDelegate,
    required this.dataDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MultiSelectTypeOptionBloc(typeOptionContext),
      child: BlocConsumer<MultiSelectTypeOptionBloc, MultiSelectTypeOptionState>(
        listener: (context, state) {
          dataDelegate.didUpdateTypeOptionData(state.typeOption.writeToBuffer());
        },
        builder: (context, state) {
          return FieldSelectOptionPannel(
            options: state.typeOption.options,
            beginEdit: () {
              overlayDelegate.hideOverlay(context);
            },
            createOptionCallback: (name) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.createOption(name));
            },
            updateOptionCallback: (updateOption) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.updateOption(updateOption));
            },
            deleteOptionCallback: (deleteOption) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.deleteOption(deleteOption));
            },
            overlayDelegate: overlayDelegate,
            key: ValueKey(state.typeOption.hashCode),
          );
        },
      ),
    );
  }
}
