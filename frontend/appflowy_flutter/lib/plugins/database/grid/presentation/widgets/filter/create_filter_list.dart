import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/simple_text_filter_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateDatabaseViewFilterList extends StatelessWidget {
  const CreateDatabaseViewFilterList({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final filterBloc = context.read<FilterEditorBloc>();
    return BlocProvider(
      create: (_) => SimpleTextFilterBloc(
        values: filterBloc.state.fields,
        comparator: (val) => val.name,
      ),
      child: BlocListener<FilterEditorBloc, FilterEditorState>(
        listenWhen: (previous, current) => previous.fields != current.fields,
        listener: (context, state) {
          context
              .read<SimpleTextFilterBloc>()
              .add(SimpleTextFilterEvent.receiveNewValues(state.fields));
        },
        child: BlocBuilder<SimpleTextFilterBloc<FieldInfo>,
            SimpleTextFilterState<FieldInfo>>(
          builder: (context, state) {
            final cells = state.values.map((fieldInfo) {
              return SizedBox(
                height: GridSize.popoverItemHeight,
                child: FilterableFieldButton(
                  fieldInfo: fieldInfo,
                  onTap: (fieldInfo) {
                    context
                        .read<FilterEditorBloc>()
                        .add(FilterEditorEvent.createFilter(fieldInfo));
                    onTap?.call();
                  },
                ),
              );
            }).toList();

            final List<Widget> slivers = [
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterTextFieldDelegate(),
              ),
              SliverToBoxAdapter(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cells.length,
                  itemBuilder: (_, int index) => cells[index],
                  separatorBuilder: (_, __) =>
                      VSpace(GridSize.typeOptionSeparatorHeight),
                ),
              ),
            ];
            return CustomScrollView(
              shrinkWrap: true,
              slivers: slivers,
              physics: StyledScrollPhysics(),
            );
          },
        ),
      ),
    );
  }
}

class _FilterTextFieldDelegate extends SliverPersistentHeaderDelegate {
  _FilterTextFieldDelegate();

  double fixHeight = 36;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      color: Theme.of(context).cardColor,
      height: fixHeight,
      child: FlowyTextField(
        hintText: LocaleKeys.grid_settings_filterBy.tr(),
        onChanged: (text) {
          context
              .read<SimpleTextFilterBloc<FieldInfo>>()
              .add(SimpleTextFilterEvent.updateFilter(text));
        },
      ),
    );
  }

  @override
  double get maxExtent => fixHeight;

  @override
  double get minExtent => fixHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class FilterableFieldButton extends StatelessWidget {
  const FilterableFieldButton({
    super.key,
    required this.fieldInfo,
    required this.onTap,
  });

  final FieldInfo fieldInfo;
  final Function(FieldInfo) onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      text: FlowyText.medium(
        lineHeight: 1.0,
        fieldInfo.field.name,
        color: AFThemeExtension.of(context).textColor,
      ),
      onTap: () => onTap(fieldInfo),
      leftIcon: FlowySvg(
        fieldInfo.fieldType.svgData,
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
