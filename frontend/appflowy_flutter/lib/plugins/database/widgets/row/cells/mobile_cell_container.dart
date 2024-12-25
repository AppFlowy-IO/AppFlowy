import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cell/editable_cell_builder.dart';
import 'cell_container.dart';

class MobileCellContainer extends StatelessWidget {
  const MobileCellContainer({
    super.key,
    required this.child,
    required this.isPrimary,
    this.onPrimaryFieldCellTap,
  });

  final EditableCellWidget child;
  final bool isPrimary;
  final VoidCallback? onPrimaryFieldCellTap;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: child.cellContainerNotifier,
      child: Selector<CellContainerNotifier, bool>(
        selector: (context, notifier) => notifier.isFocus,
        builder: (providerContext, isFocus, _) {
          Widget container = Center(child: child);

          if (isPrimary) {
            container = IgnorePointer(child: container);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isPrimary) {
                onPrimaryFieldCellTap?.call();
                return;
              }
              if (!isFocus) {
                child.requestFocus.notify();
              }
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200, minHeight: 46),
              decoration: _makeBoxDecoration(context, isPrimary, isFocus),
              child: container,
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(
    BuildContext context,
    bool isPrimary,
    bool isFocus,
  ) {
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
      border: Border(
        left: isPrimary ? borderSide : BorderSide.none,
        right: borderSide,
        bottom: borderSide,
      ),
    );
  }
}
