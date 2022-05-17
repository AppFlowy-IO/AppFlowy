import 'package:app_flowy/workspace/application/grid/field/type_option/single_select_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'select_option.dart';

class SingleSelectTypeOptionBuilder extends TypeOptionBuilder {
  final SingleSelectTypeOptionWidget _widget;

  SingleSelectTypeOptionBuilder(
    TypeOptionContext typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
    TypeOptionDataDelegate dataDelegate,
  ) : _widget = SingleSelectTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          dataDelegate: dataDelegate,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  final TypeOptionContext typeOptionContext;
  final TypeOptionOverlayDelegate overlayDelegate;
  final TypeOptionDataDelegate dataDelegate;
  const SingleSelectTypeOptionWidget({
    required this.typeOptionContext,
    required this.dataDelegate,
    required this.overlayDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SingleSelectTypeOptionBloc(typeOptionContext),
      child: BlocConsumer<SingleSelectTypeOptionBloc, SingleSelectTypeOptionState>(
        listener: (context, state) {
          dataDelegate.didUpdateTypeOptionData(state.typeOption.writeToBuffer());
        },
        builder: (context, state) {
          return SelectOptionTypeOptionWidget(
            options: state.typeOption.options,
            beginEdit: () {
              overlayDelegate.hideOverlay(context);
            },
            createSelectOptionCallback: (name) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.createOption(name));
            },
            updateSelectOptionCallback: (updateOption) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.updateOption(updateOption));
            },
            deleteSelectOptionCallback: (deleteOption) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.deleteOption(deleteOption));
            },
            overlayDelegate: overlayDelegate,
            // key: ValueKey(state.typeOption.hashCode),
          );
        },
      ),
    );
  }
}
