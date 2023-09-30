import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/grid/application/sort/sort_create_bloc.dart';
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

class GridCreateSortList extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  final VoidCallback onClosed;
  final VoidCallback? onCreateSort;

  const GridCreateSortList({
    required this.viewId,
    required this.fieldController,
    required this.onClosed,
    this.onCreateSort,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridCreateSortListState();
}

class _GridCreateSortListState extends State<GridCreateSortList> {
  late CreateSortBloc editBloc;

  @override
  void initState() {
    editBloc = CreateSortBloc(
      viewId: widget.viewId,
      fieldController: widget.fieldController,
    )..add(const CreateSortEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: editBloc,
      child: BlocListener<CreateSortBloc, CreateSortState>(
        listener: (context, state) {
          if (state.didCreateSort) {
            widget.onClosed();
          }
        },
        child: BlocBuilder<CreateSortBloc, CreateSortState>(
          builder: (context, state) {
            final cells = state.creatableFields.map((fieldInfo) {
              return SizedBox(
                height: GridSize.popoverItemHeight,
                child: GridSortPropertyCell(
                  fieldInfo: fieldInfo,
                  onTap: (fieldInfo) => createSort(fieldInfo),
                ),
              );
            }).toList();

            final List<Widget> slivers = [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SortTextFieldDelegate(),
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

  void createSort(FieldInfo field) {
    editBloc.add(CreateSortEvent.createDefaultSort(field));
    widget.onCreateSort?.call();
  }
}

class _SortTextFieldDelegate extends SliverPersistentHeaderDelegate {
  _SortTextFieldDelegate();

  double fixHeight = 36;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      height: fixHeight,
      child: FlowyTextField(
        hintText: LocaleKeys.grid_settings_sortBy.tr(),
        onChanged: (text) {
          context
              .read<CreateSortBloc>()
              .add(CreateSortEvent.didReceiveFilterText(text));
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

class GridSortPropertyCell extends StatelessWidget {
  final FieldInfo fieldInfo;
  final Function(FieldInfo) onTap;
  const GridSortPropertyCell({
    required this.fieldInfo,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      text: FlowyText.medium(
        fieldInfo.name,
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
