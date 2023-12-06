import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/field/field_controller.dart';
import '../../../application/filter/filter_create_bloc.dart';

class GridCreateFilterList extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
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
                height: GridSize.popoverItemHeight,
                child: GridFilterPropertyCell(
                  fieldInfo: fieldInfo,
                  onTap: (fieldInfo) => createFilter(fieldInfo),
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
              .read<GridCreateFilterBloc>()
              .add(GridCreateFilterEvent.didReceiveFilterText(text));
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

class GridFilterPropertyCell extends StatelessWidget {
  final FieldInfo fieldInfo;
  final Function(FieldInfo) onTap;
  const GridFilterPropertyCell({
    required this.fieldInfo,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      text: FlowyText.medium(
        fieldInfo.field.name,
        color: AFThemeExtension.of(context).textColor,
      ),
      onTap: () => onTap(fieldInfo),
      leftIcon: FlowySvg(
        fieldInfo.fieldType.icon(),
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
