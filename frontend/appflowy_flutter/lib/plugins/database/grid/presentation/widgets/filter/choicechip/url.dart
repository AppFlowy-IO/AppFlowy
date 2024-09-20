import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'choicechip.dart';

class URLFilterChoicechip extends StatelessWidget {
  const URLFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(200, 76)),
      direction: PopoverDirection.bottomWithCenterAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: TextFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<TextFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
            filterDesc: filter.getDescription(field),
          );
        },
      ),
    );
  }
}
