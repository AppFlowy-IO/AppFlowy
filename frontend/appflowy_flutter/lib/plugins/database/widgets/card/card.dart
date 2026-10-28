import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/row/action.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import '../cell/board_card_cell.dart';
import '../cell/card_cell_builder.dart';
import '../cell/card_cell_skeleton/card_cell.dart';
import 'card_bloc.dart';
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
    required this.userProfile,
    this.isCompact = false,
    this.enablePropertyEditing = false,
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

  /// Specifically the token is used to handle requests to retrieve images
  /// from cloud storage, such as the card cover.
  final UserProfilePB? userProfile;

  /// Whether the card is in a narrow space.
  /// This is used to determine eg. the Cover height.
  final bool isCompact;

  /// Enables property editors on desktop board cards.
  final bool enablePropertyEditing;

  @override
  State<RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<RowCard> {
  final popoverController = PopoverController();
  late final CardBloc _cardBloc;

  @override
  void initState() {
    super.initState();
    final rowController = RowController(
      viewId: widget.viewId,
      rowMeta: widget.rowMeta,
      rowCache: widget.rowCache,
    );

    _cardBloc = CardBloc(
      fieldController: widget.fieldController,
      viewId: widget.viewId,
      groupFieldId: widget.groupingFieldId,
      isEditing: widget.isEditing,
      rowController: rowController,
      showAllFieldsWhenEditing: widget.enablePropertyEditing,
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
      child: BlocListener<CardBloc, CardState>(
        listenWhen: (previous, current) =>
            previous.isEditing != current.isEditing,
        listener: (context, state) {
          if (!state.isEditing &&
              (!widget.enablePropertyEditing || widget.isEditing)) {
            widget.onEndEditing();
          }
        },
        child: UniversalPlatform.isMobile ? _mobile() : _desktop(),
      ),
    );
  }

  Widget _mobile() {
    return BlocBuilder<CardBloc, CardState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => widget.onTap(context),
          behavior: HitTestBehavior.opaque,
          child: MobileCardContent(
            userProfile: widget.userProfile,
            rowMeta: state.rowMeta,
            cellBuilder: widget.cellBuilder,
            styleConfiguration: widget.styleConfiguration,
            cells: state.cells,
          ),
        );
      },
    );
  }

  Widget _desktop() {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(140, 200)),
      direction: PopoverDirection.rightWithCenterAligned,
      popupBuilder: (_) => RowActionMenu.board(
        viewId: _cardBloc.viewId,
        rowId: _cardBloc.rowController.rowId,
        groupId: widget.groupId,
      ),
      child: Builder(
        builder: (context) {
          final bool isEditing = context.watch<CardBloc>().state.isEditing;
          final List<CardAccessory> accessories =
              !widget.styleConfiguration.showAccessory
                  ? const <CardAccessory>[]
                  : isEditing && widget.enablePropertyEditing
                      ? const <CardAccessory>[OpenCardAccessory()]
                      : const <CardAccessory>[
                          EditCardAccessory(),
                          MoreCardOptionsAccessory(),
                        ];
          return TapRegion(
            enabled: widget.enablePropertyEditing && isEditing,
            onTapOutside: (_) {
              // A property popup handles its own outside click first. In
              // particular, closing the date picker keeps its saved selection
              // and leaves the card open for further editing.
              if (PopoverState.rootEntry.isEmpty) {
                _finishEditing();
              }
            },
            child: RowCardContainer(
              buildAccessoryWhen: () =>
                  !isEditing || widget.enablePropertyEditing,
              accessories: accessories,
              openAccessory: (type) => _handleOpenAccessory(context, type),
              onTap: _openCard,
              onShiftTap: widget.onShiftTap,
              child: BlocBuilder<CardBloc, CardState>(
                builder: (context, state) {
                  return _CardContent(
                    rowMeta: state.rowMeta,
                    cellBuilder: widget.cellBuilder,
                    styleConfiguration: widget.styleConfiguration,
                    cells: state.cells,
                    userProfile: widget.userProfile,
                    isCompact: widget.isCompact,
                    enablePropertyEditing: widget.enablePropertyEditing,
                    isEditing: state.isEditing,
                    onDone: _finishEditing,
                    onShiftTap: widget.onShiftTap == null
                        ? null
                        : () => widget.onShiftTap!(context),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleOpenAccessory(
    BuildContext context,
    AccessoryType newAccessoryType,
  ) {
    switch (newAccessoryType) {
      case AccessoryType.edit:
        widget.onStartEditing();
        break;
      case AccessoryType.more:
        popoverController.show();
        break;
      case AccessoryType.open:
        _openCard(context);
        break;
    }
  }

  void _finishEditing() {
    // Text editors save on focus loss. Deliver that notification before the
    // card rebuilds and removes the editor, including on an outside tap down.
    FocusManager.instance
      ..primaryFocus?.unfocus()
      ..applyFocusChangesIfNeeded();
    _cardBloc.add(const CardEvent.setIsEditing(false));
  }

  void _openCard(BuildContext context) {
    if (widget.enablePropertyEditing && _cardBloc.state.isEditing) {
      _finishEditing();
    }
    widget.onTap(context);
  }
}

class _CardContent extends StatefulWidget {
  const _CardContent({
    required this.rowMeta,
    required this.cellBuilder,
    required this.cells,
    required this.styleConfiguration,
    this.userProfile,
    this.isCompact = false,
    this.enablePropertyEditing = false,
    this.onShiftTap,
    required this.isEditing,
    required this.onDone,
  });

  final RowMetaPB rowMeta;
  final CardCellBuilder cellBuilder;
  final List<CellMeta> cells;
  final RowCardStyleConfiguration styleConfiguration;
  final UserProfilePB? userProfile;
  final bool isCompact;
  final bool enablePropertyEditing;
  final VoidCallback? onShiftTap;
  final bool isEditing;
  final VoidCallback onDone;

  @override
  State<_CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<_CardContent> {
  final FocusScopeNode _focusScope = FocusScopeNode(debugLabel: 'Board card');
  final FocusNode _doneFocusNode = FocusNode(debugLabel: 'Board card Done');
  final Map<String, BoardCardFocusNode> _fieldFocusNodes =
      <String, BoardCardFocusNode>{};

  BoardCardFocusNode? _focusNodeFor(CellMeta cell) {
    final FieldInfo? field = widget
        .cellBuilder.databaseController.fieldController
        .getField(cell.fieldId);
    if (!widget.enablePropertyEditing ||
        field == null ||
        !(field.isPrimary ||
            field.fieldType == FieldType.Checkbox ||
            BoardCardCell.canEdit(field.fieldType))) {
      return null;
    }
    return _fieldFocusNodes.putIfAbsent(
      cell.fieldId,
      () => BoardCardFocusNode(debugLabel: field.name),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    if (!widget.isEditing ||
        event.logicalKey != LogicalKeyboardKey.tab ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.handled;
    }
    final List<FocusNode> targets = <FocusNode>[
      ...widget.cells.map(_focusNodeFor).whereType<BoardCardFocusNode>(),
      _doneFocusNode,
    ];
    final int current = targets.indexWhere((target) => target.hasFocus);
    if (current == -1) {
      return KeyEventResult.ignored;
    }

    // Commit the focused input before closing its popup or changing editors.
    FocusManager.instance
      ..primaryFocus?.unfocus()
      ..applyFocusChangesIfNeeded();
    while (PopoverState.rootEntry.isNotEmpty) {
      PopoverState.rootEntry.popEntry();
    }
    final int step = keyboard.isShiftPressed ? -1 : 1;
    final FocusNode next = targets[(current + step) % targets.length];
    if (next is BoardCardFocusNode) {
      next.startEditing();
    } else {
      next.requestFocus();
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    for (final BoardCardFocusNode node in _fieldFocusNodes.values) {
      node.dispose();
    }
    _doneFocusNode.dispose();
    _focusScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Column child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CardCover(
          cover: widget.rowMeta.cover,
          userProfile: widget.userProfile,
          isCompact: widget.isCompact,
        ),
        Padding(
          padding: widget.styleConfiguration.cardPadding,
          child: Column(
            children: [
              ..._makeCells(context, widget.rowMeta, widget.cells),
              if (widget.enablePropertyEditing && widget.isEditing)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DoneCardButton(
                    onPressed: widget.onDone,
                    focusNode: _doneFocusNode,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final Widget content = widget.enablePropertyEditing
        ? FocusScope(
            node: _focusScope,
            onKeyEvent: _onKeyEvent,
            child: child,
          )
        : child;
    return widget.styleConfiguration.hoverStyle == null
        ? content
        : FlowyHover(
            style: widget.styleConfiguration.hoverStyle,
            buildWhenOnHover: () => !context.read<CardBloc>().state.isEditing,
            child: content,
          );
  }

  List<Widget> _makeCells(
    BuildContext context,
    RowMetaPB rowMeta,
    List<CellMeta> cells,
  ) {
    return cells
        .mapIndexed(
          (int index, CellMeta cellMeta) => _CardContentCell(
            key: ValueKey(cellMeta.fieldId),
            cellBuilder: widget.cellBuilder,
            cellMeta: cellMeta,
            rowMeta: rowMeta,
            isTitle: index == 0,
            styleMap: widget.styleConfiguration.cellStyleMap,
            enablePropertyEditing: widget.enablePropertyEditing,
            isEditing: widget.isEditing,
            onShiftTap: widget.onShiftTap,
            focusNode: _focusNodeFor(cellMeta),
          ),
        )
        .toList();
  }
}

class _CardContentCell extends StatefulWidget {
  const _CardContentCell({
    super.key,
    required this.cellBuilder,
    required this.cellMeta,
    required this.rowMeta,
    required this.isTitle,
    required this.styleMap,
    required this.enablePropertyEditing,
    required this.isEditing,
    this.onShiftTap,
    this.focusNode,
  });

  final CellMeta cellMeta;
  final RowMetaPB rowMeta;
  final CardCellBuilder cellBuilder;
  final CardCellStyleMap styleMap;
  final bool isTitle;
  final bool enablePropertyEditing;
  final bool isEditing;
  final VoidCallback? onShiftTap;
  final BoardCardFocusNode? focusNode;

  @override
  State<_CardContentCell> createState() => _CardContentCellState();
}

class _CardContentCellState extends State<_CardContentCell> {
  late final EditableCardNotifier? cellNotifier;
  FieldController? _fieldController;
  FieldInfo? _fieldInfo;

  @override
  void initState() {
    super.initState();
    cellNotifier = widget.isTitle
        ? EditableCardNotifier(isEditing: widget.isEditing)
        : null;
    cellNotifier?.isCellEditing.addListener(listener);
    if (widget.isTitle) {
      widget.focusNode?.onRequestEditing = _editTitle;
    }
    if (widget.enablePropertyEditing) {
      _fieldController = widget.cellBuilder.databaseController.fieldController;
      _fieldInfo = _fieldController?.getField(widget.cellMeta.fieldId);
      _fieldController?.addListener(
        onReceiveFields: _onFieldsChanged,
      );
    }
  }

  void _onFieldsChanged(List<FieldInfo> fields) {
    final FieldInfo? field = fields.firstWhereOrNull(
      (field) => field.id == widget.cellMeta.fieldId,
    );
    if (mounted && field != null && field != _fieldInfo) {
      setState(() => _fieldInfo = field);
    }
  }

  void listener() {
    final bool isEditing = cellNotifier!.isCellEditing.value;
    if (widget.enablePropertyEditing && !isEditing) {
      // Changing focus between fields must not end the card's edit session.
      return;
    }
    context.read<CardBloc>().add(CardEvent.setIsEditing(isEditing));
  }

  void _editTitle() {
    if (widget.isEditing) {
      cellNotifier?.isCellEditing.value = true;
      Scrollable.ensureVisible(context);
    }
  }

  @override
  void didUpdateWidget(covariant _CardContentCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTitle && oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.onRequestEditing = null;
      widget.focusNode?.onRequestEditing = _editTitle;
    }
  }

  @override
  void dispose() {
    if (widget.isTitle) {
      widget.focusNode?.onRequestEditing = null;
    }
    cellNotifier
      ?..isCellEditing.removeListener(listener)
      ..dispose();
    _fieldController?.removeListener(
      onFieldsListener: _onFieldsChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FieldInfo? field = widget
        .cellBuilder.databaseController.fieldController
        .getField(widget.cellMeta.fieldId);
    if (widget.enablePropertyEditing &&
        field != null &&
        !field.isPrimary &&
        BoardCardCell.canEdit(field.fieldType)) {
      final CellContext cellContext = widget.cellMeta.cellContext();
      return BoardCardCell(
        key: ValueKey('${field.id}:${field.fieldType.value}'),
        databaseController: widget.cellBuilder.databaseController,
        cellContext: cellContext,
        fieldType: field.fieldType,
        fieldName: field.name,
        isCardEditing: widget.isEditing,
        focusNode: widget.focusNode,
        onShiftTap: widget.onShiftTap,
        child: widget.cellBuilder.build(
          cellContext: cellContext,
          styleMap: widget.styleMap,
          hasNotes: false,
          placeholder: widget.isEditing
              ? Padding(
                  padding: widget.styleMap[field.fieldType]?.padding ??
                      const EdgeInsets.all(4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      field.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: 11,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              : null,
        ),
      );
    }
    final BlocListener<CardBloc, CardState> child =
        BlocListener<CardBloc, CardState>(
      listenWhen: (previous, current) =>
          previous.isEditing != current.isEditing,
      listener: (context, state) {
        cellNotifier?.isCellEditing.value = state.isEditing;
      },
      child: widget.cellBuilder.build(
        cellContext: widget.cellMeta.cellContext(),
        styleMap: widget.styleMap,
        cellNotifier: cellNotifier,
        enableTitleEditing:
            widget.enablePropertyEditing && widget.isTitle && widget.isEditing,
        hasNotes: !widget.rowMeta.isDocumentEmpty,
        focusNode:
            field?.fieldType == FieldType.Checkbox ? widget.focusNode : null,
      ),
    );
    if (widget.enablePropertyEditing && !widget.isTitle) {
      // A property row belongs to its control, including read-only values and
      // the label/padding around a checkbox. Only card space opens the row.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (HardwareKeyboard.instance.isShiftPressed) {
            widget.onShiftTap?.call();
          }
        },
        child: child,
      );
    }
    return widget.isTitle && widget.focusNode != null
        ? Focus(
            focusNode: widget.focusNode,
            skipTraversal: true,
            child: child,
          )
        : child;
  }
}

class CardCover extends StatelessWidget {
  const CardCover({
    super.key,
    this.cover,
    this.userProfile,
    this.isCompact = false,
  });

  final RowCoverPB? cover;
  final UserProfilePB? userProfile;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (cover == null ||
        cover!.data.isEmpty ||
        cover!.uploadType == FileUploadTypePB.CloudFile &&
            userProfile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(child: _renderCover(context, cover!)),
        ],
      ),
    );
  }

  Widget _renderCover(BuildContext context, RowCoverPB cover) {
    final height = isCompact ? 50.0 : 100.0;

    if (cover.coverType == CoverTypePB.FileCover) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: AFImage(
          url: cover.data,
          uploadType: cover.uploadType,
          userProfile: userProfile,
        ),
      );
    }

    if (cover.coverType == CoverTypePB.AssetCover) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          PageStyleCoverImageType.builtInImagePath(cover.data),
          fit: BoxFit.cover,
        ),
      );
    }

    if (cover.coverType == CoverTypePB.ColorCover) {
      final color = FlowyTint.fromId(cover.data)?.color(context) ??
          cover.data.tryToColor();
      return Container(
        height: height,
        width: double.infinity,
        color: color,
      );
    }

    if (cover.coverType == CoverTypePB.GradientCover) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: FlowyGradientColor.fromId(cover.data).linear,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class DoneCardButton extends StatelessWidget {
  const DoneCardButton({super.key, required this.onPressed, this.focusNode});

  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      focusNode: focusNode,
      child: Text(LocaleKeys.button_done.tr()),
    );
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

class OpenCardAccessory extends StatelessWidget with CardAccessory {
  const OpenCardAccessory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: FlowySvg(
        FlowySvgs.full_view_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }

  @override
  AccessoryType get type => AccessoryType.open;
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
    this.cardPadding = const EdgeInsets.all(4),
    this.hoverStyle,
  });

  final CardCellStyleMap cellStyleMap;
  final bool showAccessory;
  final EdgeInsets cardPadding;
  final HoverStyle? hoverStyle;
}
