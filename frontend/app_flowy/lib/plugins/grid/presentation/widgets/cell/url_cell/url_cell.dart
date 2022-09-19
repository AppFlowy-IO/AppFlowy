import 'dart:async';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/cell/url_cell_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cell_accessory.dart';
import '../cell_builder.dart';
import 'cell_editor.dart';

class GridURLCellStyle extends GridCellStyle {
  String? placeholder;

  List<GridURLCellAccessoryType> accessoryTypes;

  GridURLCellStyle({
    this.placeholder,
    this.accessoryTypes = const [],
  });
}

enum GridURLCellAccessoryType {
  edit,
  copyURL,
}

class GridURLCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  late final GridURLCellStyle? cellStyle;
  GridURLCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridURLCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridURLCell> createState() => _GridURLCellState();

  GridCellAccessoryBuilder accessoryFromType(
      GridURLCellAccessoryType ty, GridCellAccessoryBuildContext buildContext) {
    switch (ty) {
      case GridURLCellAccessoryType.edit:
        final cellController =
            cellControllerBuilder.build() as GridURLCellController;
        return GridCellAccessoryBuilder(
          builder: (Key key) => _EditURLAccessory(
            key: key,
            cellContext: cellController,
            anchorContext: buildContext.anchorContext,
          ),
        );

      case GridURLCellAccessoryType.copyURL:
        final cellContext =
            cellControllerBuilder.build() as GridURLCellController;
        return GridCellAccessoryBuilder(
          builder: (Key key) => _CopyURLAccessory(
            key: key,
            cellContext: cellContext,
          ),
        );
    }
  }

  @override
  List<GridCellAccessoryBuilder> Function(
          GridCellAccessoryBuildContext buildContext)
      get accessoryBuilder => (buildContext) {
            final List<GridCellAccessoryBuilder> accessories = [];
            if (cellStyle != null) {
              accessories.addAll(cellStyle!.accessoryTypes.map((ty) {
                return accessoryFromType(ty, buildContext);
              }));
            }

            // If the accessories is empty then the default accessory will be GridURLCellAccessoryType.edit
            if (accessories.isEmpty) {
              accessories.add(accessoryFromType(
                  GridURLCellAccessoryType.edit, buildContext));
            }

            return accessories;
          };
}

class _GridURLCellState extends GridCellState<GridURLCell> {
  final _popoverController = PopoverController();
  GridURLCellController? _cellContext;
  late URLCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridURLCellController;
    _cellBloc = URLCellBloc(cellController: cellController);
    _cellBloc.add(const URLCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<URLCellBloc, URLCellState>(
        builder: (context, state) {
          final richText = RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: state.content,
              style: TextStyle(
                color: theme.main2,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          );

          return AppFlowyPopover(
            controller: _popoverController,
            constraints: BoxConstraints.loose(const Size(300, 160)),
            direction: PopoverDirection.bottomWithLeftAligned,
            offset: const Offset(0, 20),
            child: SizedBox.expand(
              child: GestureDetector(
                child: Align(alignment: Alignment.centerLeft, child: richText),
                onTap: () async {
                  final url = context.read<URLCellBloc>().state.url;
                  await _openUrlOrEdit(url);
                },
              ),
            ),
            popupBuilder: (BuildContext popoverContext) {
              return URLEditorPopover(
                cellController: _cellContext!,
              );
            },
            onClose: () {
              widget.onCellEditing.value = false;
            },
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  Future<void> _openUrlOrEdit(String url) async {
    final uri = Uri.parse(url);
    if (url.isNotEmpty && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _cellContext =
          widget.cellControllerBuilder.build() as GridURLCellController;
      widget.onCellEditing.value = true;
      _popoverController.show();
    }
  }

  @override
  void requestBeginFocus() {
    _openUrlOrEdit(_cellBloc.state.url);
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  void onInsert(String value) {
    _cellBloc.add(URLCellEvent.updateURL(value));
  }
}

class _EditURLAccessory extends StatefulWidget {
  final GridURLCellController cellContext;
  final BuildContext anchorContext;
  const _EditURLAccessory({
    required this.cellContext,
    required this.anchorContext,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EditURLAccessoryState();
}

class _EditURLAccessoryState extends State<_EditURLAccessory>
    with GridCellAccessoryState {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(300, 160)),
      controller: _popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerActionFlags.click,
      offset: const Offset(0, 20),
      child: svgWidget("editor/edit", color: theme.iconColor),
      popupBuilder: (BuildContext popoverContext) {
        return URLEditorPopover(
          cellController: widget.cellContext.clone(),
        );
      },
    );
  }

  @override
  void onTap() {
    _popoverController.show();
  }
}

class _CopyURLAccessory extends StatefulWidget {
  final GridURLCellController cellContext;
  const _CopyURLAccessory({required this.cellContext, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CopyURLAccessoryState();
}

class _CopyURLAccessoryState extends State<_CopyURLAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return svgWidget("editor/copy", color: theme.iconColor);
  }

  @override
  void onTap() {
    final content =
        widget.cellContext.getCellData(loadIfNotExist: false)?.content ?? "";
    Clipboard.setData(ClipboardData(text: content));
    showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
  }
}
