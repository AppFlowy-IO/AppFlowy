import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_create_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class GridCreateFilterList extends StatefulWidget {
  final String viewId;
  final GridFieldController fieldController;

  const GridCreateFilterList({
    required this.viewId,
    required this.fieldController,
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
      child: BlocBuilder<GridCreateFilterBloc, GridCreateFilterState>(
        builder: (context, state) {
          final cells = state.displaiedFields.map((fieldInfo) {
            return SizedBox(
              height: GridSize.typeOptionItemHeight,
              child: _FilterPropertyCell(
                fieldInfo: fieldInfo,
                onTap: (fieldInfo) => createFilter(fieldInfo),
              ),
            );
          }).toList();

          List<Widget> slivers = [
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 36,
                  child: _FilterTextField(
                    onChanged: (text) {
                      context.read<GridCreateFilterBloc>().add(
                          GridCreateFilterEvent.didReceiveFilterText(text));
                    },
                  ),
                ),
              ),
              Flexible(
                  child: CustomScrollView(
                slivers: slivers,
                controller: ScrollController(),
                physics: StyledScrollPhysics(),
              )),
            ],
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    editBloc.close();
    super.dispose();
  }

  void createFilter(GridFieldInfo field) {
    editBloc.add(GridCreateFilterEvent.createDefaultFilter(field));
  }
}

class _FilterPropertyCell extends StatelessWidget {
  final GridFieldInfo fieldInfo;
  final Function(GridFieldInfo) onTap;
  const _FilterPropertyCell({
    required this.fieldInfo,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: FlowyText.medium(fieldInfo.name, fontSize: 12),
      onTap: () => onTap(fieldInfo),
      leftIcon: svgWidget(
        fieldInfo.fieldType.iconName(),
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _FilterTextField extends StatefulWidget {
  final void Function(String) onChanged;
  const _FilterTextField({required this.onChanged, Key? key}) : super(key: key);

  @override
  State<_FilterTextField> createState() => _FilterTextFieldState();
}

class _FilterTextFieldState extends State<_FilterTextField> {
  late FocusNode focusNode;
  late TextEditingController controller;

  @override
  void initState() {
    focusNode = FocusNode();
    controller = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (text) {
        widget.onChanged(text);
      },
      maxLines: 1,
      style: TextStyles.body1.size(FontSizes.s14),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: Corners.s10Border,
        ),
        isDense: true,
        hintText: LocaleKeys.grid_settings_filterBy.tr(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: Corners.s10Border,
        ),
      ),
    );
  }
}
