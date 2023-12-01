import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '../accessory/cell_accessory.dart';
import '../accessory/cell_shortcuts.dart';
import '../cell_builder.dart';
import 'cell_container.dart';

class MobileCellContainer extends StatelessWidget {
  final GridCellWidget child;
  final AccessoryBuilder? accessoryBuilder;
  final double width;
  final bool isPrimary;

  const MobileCellContainer({
    super.key,
    required this.child,
    required this.width,
    required this.isPrimary,
    this.accessoryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: child.cellContainerNotifier,
      child: Selector<CellContainerNotifier, bool>(
        selector: (context, notifier) => notifier.isFocus,
        builder: (providerContext, isFocus, _) {
          Widget container = Center(child: GridCellShortcuts(child: child));

          if (accessoryBuilder != null) {
            final accessories = accessoryBuilder!.call(
              GridCellAccessoryBuildContext(
                anchorContext: context,
                isCellEditing: isFocus,
              ),
            );

            if (accessories.isNotEmpty) {
              container = _GridCellEnterRegion(
                accessories: accessories,
                isPrimary: isPrimary,
                child: container,
              );
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!isFocus) {
                child.requestFocus.notify();
              }
            },
            child: Container(
              constraints: BoxConstraints(maxWidth: width, minHeight: 46),
              decoration: _makeBoxDecoration(context, isFocus),
              child: container,
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context, bool isFocus) {
    if (isFocus) {
      return BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final borderSide = BorderSide(color: Theme.of(context).dividerColor);
    return BoxDecoration(
      border: Border(right: borderSide, bottom: borderSide),
    );
  }
}

class _GridCellEnterRegion extends StatelessWidget {
  const _GridCellEnterRegion({
    required this.child,
    required this.accessories,
    required this.isPrimary,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final List<GridCellAccessoryBuilder> accessories;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Selector<CellContainerNotifier, bool>(
      selector: (context, cellNotifier) => !cellNotifier.isFocus && isPrimary,
      builder: (context, showAccessory, _) {
        final List<Widget> children = [child];

        if (showAccessory) {
          children.add(
            CellAccessoryContainer(accessories: accessories).positioned(
              right: GridSize.cellContentInsets.right,
            ),
          );
        }

        return Stack(
          alignment: AlignmentDirectional.center,
          fit: StackFit.expand,
          children: children,
        );
      },
    );
  }
}
