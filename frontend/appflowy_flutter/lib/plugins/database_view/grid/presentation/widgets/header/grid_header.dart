import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_header_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';
import '../../../../application/field/type_option/type_option_service.dart';
import '../../layout/sizes.dart';
import 'field_editor.dart';
import 'field_cell.dart';

class GridHeaderSliverAdaptor extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  final ScrollController anchorScrollController;

  const GridHeaderSliverAdaptor({
    required this.viewId,
    required this.fieldController,
    required this.anchorScrollController,
    Key? key,
  }) : super(key: key);

  @override
  State<GridHeaderSliverAdaptor> createState() =>
      _GridHeaderSliverAdaptorState();
}

class _GridHeaderSliverAdaptorState extends State<GridHeaderSliverAdaptor> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<GridHeaderBloc>(
          param1: widget.viewId,
          param2: widget.fieldController,
        );
        bloc.add(const GridHeaderEvent.initial());
        return bloc;
      },
      child: BlocBuilder<GridHeaderBloc, GridHeaderState>(
        buildWhen: (previous, current) =>
            previous.fields.length != current.fields.length,
        builder: (context, state) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: widget.anchorScrollController,
            child: SizedBox(
              height: GridSize.headerHeight,
              child: _GridHeader(viewId: widget.viewId),
            ),
          );
        },
      ),
    );
  }
}

class _GridHeader extends StatefulWidget {
  final String viewId;
  const _GridHeader({Key? key, required this.viewId}) : super(key: key);

  @override
  State<_GridHeader> createState() => _GridHeaderState();
}

class _GridHeaderState extends State<_GridHeader> {
  final Map<String, ValueKey<String>> _gridMap = {};

  /// This is a workaround for [ReorderableRow].
  /// [ReorderableRow] warps the child's key with a [GlobalKey].
  /// It will trigger the child's widget's to recreate.
  /// The state will lose.
  _getKeyById(String id) {
    if (_gridMap.containsKey(id)) {
      return _gridMap[id];
    }
    final newKey = ValueKey(id);
    _gridMap[id] = newKey;
    return newKey;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridHeaderBloc, GridHeaderState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        final cells = state.fields
            .where((field) => field.visibility)
            .map(
              (field) => FieldContext(
                viewId: widget.viewId,
                field: field.field,
              ),
            )
            .map(
              (ctx) => GridFieldCell(
                key: _getKeyById(ctx.field.id),
                cellContext: ctx,
              ),
            )
            .toList();

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: RepaintBoundary(
            child: ReorderableRow(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              scrollController: ScrollController(),
              header: const _CellLeading(),
              needsLongPressDraggable: false,
              footer: _CellTrailing(viewId: widget.viewId),
              onReorder: (int oldIndex, int newIndex) {
                _onReorder(cells, oldIndex, context, newIndex);
              },
              children: cells,
            ),
          ),
        );
      },
    );
  }

  void _onReorder(
    List<GridFieldCell> cells,
    int oldIndex,
    BuildContext context,
    int newIndex,
  ) {
    if (cells.length > oldIndex) {
      final field = cells[oldIndex].cellContext.field;
      context
          .read<GridHeaderBloc>()
          .add(GridHeaderEvent.moveField(field, oldIndex, newIndex));
    }
  }
}

class _CellLeading extends StatelessWidget {
  const _CellLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GridSize.leadingHeaderPadding,
    );
  }
}

class _CellTrailing extends StatelessWidget {
  final String viewId;
  const _CellTrailing({required this.viewId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderSide =
        BorderSide(color: Theme.of(context).dividerColor, width: 1.0);
    return Container(
      width: GridSize.trailHeaderPadding,
      decoration: BoxDecoration(
        border: Border(top: borderSide, bottom: borderSide),
      ),
      padding: GridSize.headerContentInsets,
      child: CreateFieldButton(viewId: viewId),
    );
  }
}

class CreateFieldButton extends StatefulWidget {
  final String viewId;
  const CreateFieldButton({required this.viewId, Key? key}) : super(key: key);

  @override
  State<CreateFieldButton> createState() => _CreateFieldButtonState();
}

class _CreateFieldButtonState extends State<CreateFieldButton> {
  final popoverController = PopoverController();
  late TypeOptionPB typeOption;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithRightAligned,
      asBarrier: true,
      margin: EdgeInsets.zero,
      constraints: BoxConstraints.loose(const Size(240, 600)),
      triggerActions: PopoverTriggerFlags.none,
      child: FlowyButton(
        radius: BorderRadius.zero,
        text: FlowyText.medium(LocaleKeys.grid_field_newProperty.tr()),
        hoverColor: AFThemeExtension.of(context).greyHover,
        onTap: () async {
          final result = await TypeOptionBackendService.createFieldTypeOption(
            viewId: widget.viewId,
          );
          result.fold(
            (l) {
              typeOption = l;
              popoverController.show();
            },
            (r) => Log.error("Failed to create field type option: $r"),
          );
        },
        leftIcon: const FlowySvg(name: 'home/add'),
      ),
      popupBuilder: (BuildContext popover) {
        return FieldEditor(
          viewId: widget.viewId,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: typeOption.field_2,
          ),
        );
      },
    );
  }
}

class SliverHeaderDelegateImplementation
    extends SliverPersistentHeaderDelegate {
  final String gridId;
  final List<FieldPB> fields;

  SliverHeaderDelegateImplementation({
    required this.gridId,
    required this.fields,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _GridHeader(viewId: gridId);
  }

  @override
  double get maxExtent => GridSize.headerHeight;

  @override
  double get minExtent => GridSize.headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is SliverHeaderDelegateImplementation) {
      return fields.length != oldDelegate.fields.length;
    }
    return true;
  }
}
