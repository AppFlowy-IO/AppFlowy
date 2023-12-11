import 'dart:async';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../grid/presentation/layout/sizes.dart';
import '../../accessory/cell_accessory.dart';
import '../../cell_builder.dart';
import 'url_cell_bloc.dart';

class GridURLCellStyle extends GridCellStyle {
  String? placeholder;
  TextStyle? textStyle;
  bool? autofocus;
  EdgeInsets? cellPadding;

  List<GridURLCellAccessoryType> accessoryTypes;

  GridURLCellStyle({
    this.placeholder,
    this.accessoryTypes = const [],
    this.cellPadding,
  });
}

enum GridURLCellAccessoryType {
  copyURL,
  visitURL,
}

typedef URLCellDataNotifier = CellDataNotifier<String>;

class GridURLCell extends GridCellWidget {
  GridURLCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  }) : _cellDataNotifier = CellDataNotifier(value: '') {
    if (style != null) {
      cellStyle = (style as GridURLCellStyle);
    } else {
      cellStyle = GridURLCellStyle();
    }
  }

  /// Use
  final URLCellDataNotifier _cellDataNotifier;
  final CellControllerBuilder cellControllerBuilder;
  late final GridURLCellStyle cellStyle;

  @override
  GridCellState<GridURLCell> createState() => _GridURLCellState();

  @override
  List<GridCellAccessoryBuilder> Function(
    GridCellAccessoryBuildContext buildContext,
  ) get accessoryBuilder => (buildContext) {
        final List<GridCellAccessoryBuilder> accessories = [];
        accessories.addAll(
          cellStyle.accessoryTypes.map((ty) {
            return _accessoryFromType(ty, buildContext);
          }),
        );

        // If the accessories is empty then the default accessory will be GridURLCellAccessoryType.visitURL
        if (accessories.isEmpty) {
          accessories.add(
            _accessoryFromType(
              GridURLCellAccessoryType.visitURL,
              buildContext,
            ),
          );
        }

        return accessories;
      };

  GridCellAccessoryBuilder _accessoryFromType(
    GridURLCellAccessoryType ty,
    GridCellAccessoryBuildContext buildContext,
  ) {
    switch (ty) {
      case GridURLCellAccessoryType.visitURL:
        return VisitURLCellAccessoryBuilder(
          builder: (Key key) => _VisitURLAccessory(
            key: key,
            cellDataNotifier: _cellDataNotifier,
          ),
        );
      case GridURLCellAccessoryType.copyURL:
        return CopyURLCellAccessoryBuilder(
          builder: (Key key) => _CopyURLAccessory(
            key: key,
            cellDataNotifier: _cellDataNotifier,
          ),
        );
    }
  }
}

class _GridURLCellState extends GridEditableTextCell<GridURLCell> {
  late final URLCellBloc _cellBloc;
  late final TextEditingController _controller;

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

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
        listener: (context, state) {
          _controller.text = state.content;
        },
        builder: (context, state) {
          final style = widget.cellStyle.textStyle ??
              Theme.of(context).textTheme.bodyMedium!;
          widget._cellDataNotifier.value = state.content;
          return TextField(
            controller: _controller,
            focusNode: focusNode,
            maxLines: null,
            style: style.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            autofocus: false,
            decoration: InputDecoration(
              contentPadding:
                  widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: widget.cellStyle.placeholder,
              hintStyle: style.copyWith(color: Theme.of(context).hintColor),
              isDense: true,
            ),
            onTapOutside: (_) => focusNode.unfocus(),
          );
        },
      ),
    );
  }

  @override
  Future<void> focusChanged() async {
    _cellBloc.add(URLCellEvent.updateURL(_controller.text.trim()));
    return super.focusChanged();
  }

  @override
  String? onCopy() => _cellBloc.state.content;
}

typedef CopyURLCellAccessoryBuilder
    = GridCellAccessoryBuilder<State<_CopyURLAccessory>>;

class _CopyURLAccessory extends StatefulWidget {
  const _CopyURLAccessory({
    super.key,
    required this.cellDataNotifier,
  });

  final URLCellDataNotifier cellDataNotifier;

  @override
  State<_CopyURLAccessory> createState() => _CopyURLAccessoryState();
}

class _CopyURLAccessoryState extends State<_CopyURLAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    if (widget.cellDataNotifier.value.isNotEmpty) {
      return FlowyTooltip(
        message: LocaleKeys.tooltip_urlCopyAccessory.tr(),
        preferBelow: false,
        child: _URLAccessoryIconContainer(
          child: FlowySvg(
            FlowySvgs.copy_s,
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  void onTap() {
    final content = widget.cellDataNotifier.value;
    if (content.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: content));
    showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
  }
}

typedef VisitURLCellAccessoryBuilder
    = GridCellAccessoryBuilder<State<_VisitURLAccessory>>;

class _VisitURLAccessory extends StatefulWidget {
  const _VisitURLAccessory({
    super.key,
    required this.cellDataNotifier,
  });

  final URLCellDataNotifier cellDataNotifier;

  @override
  State<_VisitURLAccessory> createState() => _VisitURLAccessoryState();
}

class _VisitURLAccessoryState extends State<_VisitURLAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    if (widget.cellDataNotifier.value.isNotEmpty) {
      return FlowyTooltip(
        message: LocaleKeys.tooltip_urlLaunchAccessory.tr(),
        preferBelow: false,
        child: _URLAccessoryIconContainer(
          child: FlowySvg(
            FlowySvgs.attach_s,
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  bool enable() {
    return widget.cellDataNotifier.value.isNotEmpty;
  }

  @override
  void onTap() {
    final content = widget.cellDataNotifier.value;
    if (content.isEmpty) {
      return;
    }
    final shouldAddScheme =
        !['http', 'https'].any((pattern) => content.startsWith(pattern));
    final url = shouldAddScheme ? 'http://$content' : content;
    canLaunchUrlString(url).then((value) => launchUrlString(url));
  }
}

class _URLAccessoryIconContainer extends StatelessWidget {
  const _URLAccessoryIconContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: child,
      ),
    );
  }
}
