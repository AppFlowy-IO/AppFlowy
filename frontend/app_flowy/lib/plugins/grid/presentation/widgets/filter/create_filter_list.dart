import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_create_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridCreateFilterList extends StatefulWidget {
  final String viewId;
  final GridFieldController fieldController;
  final VoidCallback onClosed;
  final VoidCallback? onCreateFilter;

  const GridCreateFilterList({
    required this.viewId,
    required this.fieldController,
    required this.onClosed,
    this.onCreateFilter,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridCreateFilterListState();
}

class _GridCreateFilterListState extends State<GridCreateFilterList> {
  late GridCreateFilterBloc editBloc;

  @override
  void initState() {
    editBloc = GridCreateFilterBloc(
      viewId: widget.viewId,
      fieldController: widget.fieldController,
    )..add(const GridCreateFilterEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: editBloc,
      child: BlocListener<GridCreateFilterBloc, GridCreateFilterState>(
        listener: (context, state) {
          if (state.didCreateFilter) {
            widget.onClosed();
          }
        },
        child: BlocBuilder<GridCreateFilterBloc, GridCreateFilterState>(
          builder: (context, state) {
            final cells = state.creatableFields.map((fieldInfo) {
              return SizedBox(
                height: GridSize.typeOptionItemHeight,
                child: _FilterPropertyCell(
                  fieldInfo: fieldInfo,
                  onTap: (fieldInfo) => createFilter(fieldInfo),
                ),
              );
            }).toList();

            List<Widget> slivers = [
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterTextFieldDelegate(),
              ),
              SliverToBoxAdapter(
                child: ListView.separated(
                  controller: ScrollController(),
                  shrinkWrap: true,
                  itemCount: cells.length,
                  itemBuilder: (BuildContext context, int index) {
                    return cells[index];
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return VSpace(GridSize.typeOptionSeparatorHeight);
                  },
                ),
              ),
            ];
            return CustomScrollView(
              shrinkWrap: true,
              slivers: slivers,
              controller: ScrollController(),
              physics: StyledScrollPhysics(),
            );
          },
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    editBloc.close();
    super.dispose();
  }

  void createFilter(FieldInfo field) {
    editBloc.add(GridCreateFilterEvent.createDefaultFilter(field));
    widget.onCreateFilter?.call();
  }
}

class _FilterTextFieldDelegate extends SliverPersistentHeaderDelegate {
  _FilterTextFieldDelegate();

  double fixHeight = 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        height: fixHeight,
        child: FlowyTextField(
          hintText: LocaleKeys.grid_settings_filterBy.tr(),
          onChanged: (text) {
            context
                .read<GridCreateFilterBloc>()
                .add(GridCreateFilterEvent.didReceiveFilterText(text));
          },
        ),
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

class _FilterPropertyCell extends StatelessWidget {
  final FieldInfo fieldInfo;
  final Function(FieldInfo) onTap;
  const _FilterPropertyCell({
    required this.fieldInfo,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: FlowyText.medium(fieldInfo.name),
      onTap: () => onTap(fieldInfo),
      leftIcon: svgWidget(
        fieldInfo.fieldType.iconName(),
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
