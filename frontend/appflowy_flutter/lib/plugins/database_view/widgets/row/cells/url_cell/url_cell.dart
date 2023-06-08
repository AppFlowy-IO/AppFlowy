import 'dart:async';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../grid/presentation/layout/sizes.dart';
import '../../accessory/cell_accessory.dart';
import '../../cell_builder.dart';
import 'cell_editor.dart';
import 'url_cell_bloc.dart';

class GridURLCellStyle extends GridCellStyle {
  String? placeholder;
  TextStyle? textStyle;
  bool? autofocus;

  List<GridURLCellAccessoryType> accessoryTypes;

  GridURLCellStyle({
    this.placeholder,
    this.accessoryTypes = const [],
  });
}

enum GridURLCellAccessoryType {
  copyURL,
  visitURL,
}

class GridURLCell extends GridCellWidget {
  GridURLCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  }) {
    if (style != null) {
      cellStyle = (style as GridURLCellStyle);
    } else {
      cellStyle = null;
    }
  }

  final CellControllerBuilder cellControllerBuilder;
  late final GridURLCellStyle? cellStyle;

  @override
  GridCellState<GridURLCell> createState() => _GridURLCellState();

  GridCellAccessoryBuilder accessoryFromType(
    GridURLCellAccessoryType ty,
    GridCellAccessoryBuildContext buildContext,
  ) {
    switch (ty) {
      case GridURLCellAccessoryType.visitURL:
        final cellContext = cellControllerBuilder.build() as URLCellController;
        return GridCellAccessoryBuilder(
          builder: (Key key) => _VisitURLAccessory(
            key: key,
            cellContext: cellContext,
          ),
        );
      case GridURLCellAccessoryType.copyURL:
        final cellContext = cellControllerBuilder.build() as URLCellController;
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
    GridCellAccessoryBuildContext buildContext,
  ) get accessoryBuilder => (buildContext) {
        final List<GridCellAccessoryBuilder> accessories = [];
        if (cellStyle != null) {
          accessories.addAll(
            cellStyle!.accessoryTypes.map((ty) {
              return accessoryFromType(ty, buildContext);
            }),
          );
        }

        // If the accessories is empty then the default accessory will be GridURLCellAccessoryType.visitURL
        if (accessories.isEmpty) {
          accessories.add(
            accessoryFromType(
              GridURLCellAccessoryType.visitURL,
              buildContext,
            ),
          );
        }

        return accessories;
      };
}

class _GridURLCellState extends GridFocusNodeCellState<GridURLCell> {
  final _popoverController = PopoverController();
  late final URLCellBloc _cellBloc;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    final cellController =
        widget.cellControllerBuilder.build() as URLCellController;
    _cellBloc = URLCellBloc(cellController: cellController)
      ..add(const URLCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocConsumer<URLCellBloc, URLCellState>(
        listenWhen: (previous, current) => previous.content != current.content,
        listener: (context, state) => _controller.text = state.content,
        builder: (context, state) {
          final urlEditor = Padding(
            padding: EdgeInsets.only(
              left: GridSize.cellContentInsets.left,
              right: GridSize.cellContentInsets.right,
            ),
            child: TextField(
              controller: _controller,
              focusNode: focusNode,
              maxLines: 1,
              style: (widget.cellStyle?.textStyle ??
                      Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              autofocus: false,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(
                  top: GridSize.cellContentInsets.top,
                  bottom: GridSize.cellContentInsets.bottom,
                ),
                border: InputBorder.none,
                hintText: widget.cellStyle?.placeholder,
                isDense: true,
              ),
            ),
          );
          return urlEditor;
        },
      ),
    );
  }

  @override
  Future<void> focusChanged() async {
    _cellBloc.add(URLCellEvent.updateURL(_controller.text));
    return super.focusChanged();
  }

  @override
  void requestBeginFocus() {
    widget.onCellEditing.value = true;
    _popoverController.show();
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  void onInsert(String value) => _cellBloc.add(URLCellEvent.updateURL(value));
}

class _EditURLAccessory extends StatefulWidget {
  const _EditURLAccessory({
    required this.cellControllerBuilder,
    required this.anchorContext,
  });

  final CellControllerBuilder cellControllerBuilder;
  final BuildContext anchorContext;

  @override
  State<StatefulWidget> createState() => _EditURLAccessoryState();
}

class _EditURLAccessoryState extends State<_EditURLAccessory>
    with GridCellAccessoryState {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      margin: EdgeInsets.zero,
      constraints: BoxConstraints.loose(const Size(300, 160)),
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 8),
      child: svgWidget(
        "editor/edit",
        color: AFThemeExtension.of(context).textColor,
      ),
      popupBuilder: (BuildContext popoverContext) {
        return URLEditorPopover(
          cellController:
              widget.cellControllerBuilder.build() as URLCellController,
          onExit: () => popoverController.close(),
        );
      },
    );
  }

  @override
  void onTap() {
    popoverController.show();
  }
}

class _CopyURLAccessory extends StatefulWidget {
  const _CopyURLAccessory({
    super.key,
    required this.cellContext,
  });

  final URLCellController cellContext;

  @override
  State<StatefulWidget> createState() => _CopyURLAccessoryState();
}

class _CopyURLAccessoryState extends State<_CopyURLAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    return svgWidget(
      "editor/copy",
      color: AFThemeExtension.of(context).textColor,
    );
  }

  @override
  void onTap() {
    final content =
        widget.cellContext.getCellData(loadIfNotExist: false)?.content;
    if (content == null) {
      return;
    }
    Clipboard.setData(ClipboardData(text: content));
    showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
  }
}

class _VisitURLAccessory extends StatefulWidget {
  const _VisitURLAccessory({
    super.key,
    required this.cellContext,
  });

  final URLCellController cellContext;

  @override
  State<StatefulWidget> createState() => _VisitURLAccessoryState();
}

class _VisitURLAccessoryState extends State<_VisitURLAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    return svgWidget(
      "editor/link",
      color: AFThemeExtension.of(context).textColor,
    );
  }

  @override
  void onTap() {
    final content =
        widget.cellContext.getCellData(loadIfNotExist: false)?.content;
    if (content == null) {
      return;
    }
    final shouldAddScheme =
        !['http', 'https'].any((pattern) => content.startsWith(pattern));
    final url = shouldAddScheme ? 'http://$content' : content;
    canLaunchUrlString(url).then((value) => launchUrlString(url));
  }
}
