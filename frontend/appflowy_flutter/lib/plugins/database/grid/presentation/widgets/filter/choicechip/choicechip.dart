import 'dart:math' as math;

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({
    super.key,
    required this.fieldInfo,
    this.filterDesc = '',
    this.onTap,
  });

  final FieldInfo fieldInfo;
  final String filterDesc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final buttonText =
        filterDesc.isEmpty ? fieldInfo.name : "${fieldInfo.name}: $filterDesc";

    return SizedBox(
      height: 28,
      child: FlowyButton(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.fromBorderSide(
            BorderSide(
              color: AFThemeExtension.of(context).toggleOffFill,
            ),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        useIntrinsicWidth: true,
        text: FlowyText(
          buttonText,
          lineHeight: 1.0,
          color: AFThemeExtension.of(context).textColor,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        radius: const BorderRadius.all(Radius.circular(14)),
        leftIcon: FieldIcon(
          fieldInfo: fieldInfo,
        ),
        rightIcon: const _ChoicechipDownArrow(),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: onTap,
      ),
    );
  }
}

class _ChoicechipDownArrow extends StatelessWidget {
  const _ChoicechipDownArrow();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 2,
      child: FlowySvg(
        FlowySvgs.arrow_left_s,
        color: AFThemeExtension.of(context).textColor,
      ),
    );
  }
}

class SingleFilterBlocSelector<T extends DatabaseFilter>
    extends StatelessWidget {
  const SingleFilterBlocSelector({
    super.key,
    required this.filterId,
    required this.builder,
  });

  final String filterId;
  final Widget Function(BuildContext, T, FieldInfo) builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FilterEditorBloc, FilterEditorState, (T, FieldInfo)?>(
      selector: (state) {
        final filter = state.filters
            .firstWhereOrNull((filter) => filter.filterId == filterId) as T?;
        if (filter == null) {
          return null;
        }
        final field = state.fields
            .firstWhereOrNull((field) => field.id == filter.fieldId);
        if (field == null) {
          return null;
        }
        return (filter, field);
      },
      builder: (context, selection) {
        if (selection == null) {
          return const SizedBox.shrink();
        }
        return builder(context, selection.$1, selection.$2);
      },
    );
  }
}
