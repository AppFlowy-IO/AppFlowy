import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/url.dart';

class DesktopGridURLSkin extends IEditableURLCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return BlocSelector<URLCellBloc, URLCellState, bool>(
      selector: (state) => state.wrap,
      builder: (context, wrap) => TextField(
        controller: textEditingController,
        focusNode: focusNode,
        maxLines: wrap ? null : 1,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
        decoration: InputDecoration(
          contentPadding: GridSize.cellContentInsets,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintStyle: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).hintColor),
          isDense: true,
        ),
        onTapOutside: (_) => focusNode.unfocus(),
      ),
    );
  }

  @override
  List<GridCellAccessoryBuilder> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return [
      accessoryFromType(
        GridURLCellAccessoryType.visitURL,
        cellDataNotifier,
      ),
      accessoryFromType(
        GridURLCellAccessoryType.copyURL,
        cellDataNotifier,
      ),
    ];
  }
}

GridCellAccessoryBuilder accessoryFromType(
  GridURLCellAccessoryType ty,
  URLCellDataNotifier cellDataNotifier,
) {
  switch (ty) {
    case GridURLCellAccessoryType.visitURL:
      return VisitURLCellAccessoryBuilder(
        builder: (Key key) => _VisitURLAccessory(
          key: key,
          cellDataNotifier: cellDataNotifier,
        ),
      );
    case GridURLCellAccessoryType.copyURL:
      return CopyURLCellAccessoryBuilder(
        builder: (Key key) => _CopyURLAccessory(
          key: key,
          cellDataNotifier: cellDataNotifier,
        ),
      );
  }
}

enum GridURLCellAccessoryType {
  copyURL,
  visitURL,
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
        message: LocaleKeys.grid_url_copy.tr(),
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
        message: LocaleKeys.grid_url_launch.tr(),
        preferBelow: false,
        child: _URLAccessoryIconContainer(
          child: FlowySvg(
            FlowySvgs.url_s,
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  bool enable() => widget.cellDataNotifier.value.isNotEmpty;

  @override
  void onTap() => openUrlCellLink(widget.cellDataNotifier.value);
}

class _URLAccessoryIconContainer extends StatelessWidget {
  const _URLAccessoryIconContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: Theme.of(context).dividerColor),
        ),
        borderRadius: Corners.s6Border,
      ),
      child: FlowyHover(
        style: HoverStyle(
          backgroundColor: AFThemeExtension.of(context).background,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
