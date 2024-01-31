import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      maxLines: null,
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
