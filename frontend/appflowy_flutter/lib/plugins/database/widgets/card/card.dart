import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/row/action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_bloc.dart';
import '../cell/card_cell_builder.dart';
import '../cell/card_cell_skeleton/card_cell.dart';
import 'container/accessory.dart';
import 'container/card_container.dart';

/// Edit a database row with card style widget
class RowCard extends StatefulWidget {
  const RowCard({
    super.key,
    required this.fieldController,
    required this.rowMeta,
    required this.viewId,
    required this.isEditing,
    required this.rowCache,
    required this.cellBuilder,
    required this.onTap,
    required this.onStartEditing,
    required this.onEndEditing,
    required this.styleConfiguration,
    this.onShiftTap,
    this.groupingFieldId,
    this.groupId,
  });

  final FieldController fieldController;
  final RowMetaPB rowMeta;
  final String viewId;
  final String? groupingFieldId;
  final String? groupId;

  final bool isEditing;
  final RowCache rowCache;

  /// The [CardCellBuilder] is used to build the card cells.
  final CardCellBuilder cellBuilder;

  /// Called when the user taps on the card.
  final void Function(BuildContext context) onTap;

  final void Function(BuildContext context)? onShiftTap;

  /// Called when the user starts editing the card.
  final VoidCallback onStartEditing;

  /// Called when the user ends editing the card.
  final VoidCallback onEndEditing;

  final RowCardStyleConfiguration styleConfiguration;

  @override
  State<RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<RowCard> {
  final popoverController = PopoverController();
  late final CardBloc _cardBloc;

  @override
  void initState() {
    super.initState();
    _cardBloc = CardBloc(
      fieldController: widget.fieldController,
      viewId: widget.viewId,
      groupFieldId: widget.groupingFieldId,
      isEditing: widget.isEditing,
      rowMeta: widget.rowMeta,
      rowCache: widget.rowCache,
    )..add(const CardEvent.initial());
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    if (widget.isEditing != _cardBloc.state.isEditing) {
      _cardBloc.add(CardEvent.setIsEditing(widget.isEditing));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _cardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cardBloc,
      child: BlocConsumer<CardBloc, CardState>(
        listenWhen: (previous, current) =>
            previous.isEditing != current.isEditing,
        listener: (context, state) {
          if (!state.isEditing) {
            widget.onEndEditing();
          }
        },
        builder: (context, state) =>
            PlatformExtension.isMobile ? _mobile(state) : _desktop(state),
      ),
    );
  }

  Widget _mobile(CardState state) {
    return GestureDetector(
      onTap: () => widget.onTap(context),
      behavior: HitTestBehavior.opaque,
      child: MobileCardContent(
        rowMeta: state.rowMeta,
        cellBuilder: widget.cellBuilder,
        styleConfiguration: widget.styleConfiguration,
        cells: state.cells,
      ),
    );
  }

  Widget _desktop(CardState state) {
    final accessories = widget.styleConfiguration.showAccessory
        ? const <CardAccessory>[
            EditCardAccessory(),
            MoreCardOptionsAccessory(),
          ]
        : null;
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(140, 200)),
      direction: PopoverDirection.rightWithCenterAligned,
      popupBuilder: (_) {
        return RowActionMenu.board(
          viewId: _cardBloc.viewId,
          rowId: _cardBloc.rowId,
          groupId: widget.groupId,
        );
      },
      child: RowCardContainer(
        buildAccessoryWhen: () => state.isEditing == false,
        accessories: accessories ?? [],
        openAccessory: _handleOpenAccessory,
        onTap: widget.onTap,
        onShiftTap: widget.onShiftTap,
        child: _CardContent(
          rowMeta: state.rowMeta,
          cellBuilder: widget.cellBuilder,
          styleConfiguration: widget.styleConfiguration,
          cells: state.cells,
        ),
      ),
    );
  }

  void _handleOpenAccessory(AccessoryType newAccessoryType) {
    switch (newAccessoryType) {
      case AccessoryType.edit:
        widget.onStartEditing();
        break;
      case AccessoryType.more:
        popoverController.show();
        break;
    }
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.rowMeta,
    required this.cellBuilder,
    required this.cells,
    required this.styleConfiguration,
  });

  final RowMetaPB rowMeta;
  final CardCellBuilder cellBuilder;
  final List<CellContext> cells;
  final RowCardStyleConfiguration styleConfiguration;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: styleConfiguration.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _makeCells(context, rowMeta, cells),
      ),
    );
    return styleConfiguration.hoverStyle == null
        ? child
        : FlowyHover(
            style: styleConfiguration.hoverStyle,
            buildWhenOnHover: () => !context.read<CardBloc>().state.isEditing,
            child: child,
          );
  }

  List<Widget> _makeCells(
    BuildContext context,
    RowMetaPB rowMeta,
    List<CellContext> cells,
  ) {
    return cells.mapIndexed((int index, CellContext cellContext) {
      EditableCardNotifier? cellNotifier;

      if (index == 0) {
        final bloc = context.read<CardBloc>();
        cellNotifier = EditableCardNotifier(isEditing: bloc.state.isEditing);
        cellNotifier.isCellEditing.addListener(() {
          final isEditing = cellNotifier!.isCellEditing.value;
          bloc.add(CardEvent.setIsEditing(isEditing));
        });
      }

      return cellBuilder.build(
        cellContext: cellContext,
        cellNotifier: cellNotifier,
        styleMap: styleConfiguration.cellStyleMap,
        hasNotes: !rowMeta.isDocumentEmpty,
      );
    }).toList();
  }
}

class EditCardAccessory extends StatelessWidget with CardAccessory {
  const EditCardAccessory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: FlowySvg(
        FlowySvgs.edit_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }

  @override
  AccessoryType get type => AccessoryType.edit;
}

class MoreCardOptionsAccessory extends StatelessWidget with CardAccessory {
  const MoreCardOptionsAccessory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: FlowySvg(
        FlowySvgs.three_dots_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }

  @override
  AccessoryType get type => AccessoryType.more;
}

class RowCardStyleConfiguration {
  const RowCardStyleConfiguration({
    required this.cellStyleMap,
    this.showAccessory = true,
    this.cardPadding = const EdgeInsets.all(8),
    this.hoverStyle,
  });

  final CardCellStyleMap cellStyleMap;
  final bool showAccessory;
  final EdgeInsets cardPadding;
  final HoverStyle? hoverStyle;
}
