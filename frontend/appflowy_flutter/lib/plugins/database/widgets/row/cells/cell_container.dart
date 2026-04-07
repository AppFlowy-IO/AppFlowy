import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../../grid/presentation/layout/sizes.dart';
import '../../../grid/presentation/widgets/row/row.dart';
import '../../cell/editable_cell_builder.dart';
import '../accessory/cell_accessory.dart';
import '../accessory/cell_shortcuts.dart';

class CellContainer extends StatefulWidget {
  const CellContainer({
    super.key,
    required this.child,
    required this.width,
    required this.isPrimary,
    this.accessoryBuilder,
  });

  final EditableCellWidget child;
  final AccessoryBuilder? accessoryBuilder;
  final double width;
  final bool isPrimary;

  @override
  State<CellContainer> createState() => _CellContainerState();
}

class _CellContainerState extends State<CellContainer> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.child.cellContainerNotifier,
      child: Selector<CellContainerNotifier, bool>(
        selector: (context, notifier) => notifier.isFocus,
        builder: (providerContext, isChildFocus, _) {
          Widget container = Center(child: GridCellShortcuts(child: widget.child));

          if (widget.accessoryBuilder != null) {
            final accessories = widget.accessoryBuilder!.call(
              GridCellAccessoryBuildContext(
                anchorContext: context,
                isCellEditing: isChildFocus,
              ),
            );

            if (accessories.isNotEmpty) {
              container = _GridCellEnterRegion(
                accessories: accessories,
                isPrimary: widget.isPrimary,
                child: container,
              );
            }
          }

          final isSelectedOrEditing = isChildFocus || _focusNode.hasFocus;

          return Focus(
            focusNode: _focusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  widget.child.requestFocus.notify();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isChildFocus) {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  } else {
                    widget.child.requestFocus.notify();
                  }
                }
              },
              onDoubleTap: () {
                if (!isChildFocus) {
                  widget.child.requestFocus.notify();
                }
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: widget.width, minHeight: 32),
                decoration: _makeBoxDecoration(context, isSelectedOrEditing),
                child: container,
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context, bool isFocus) {
    if (isFocus) {
      final borderSide = BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      );

      return BoxDecoration(border: Border.fromBorderSide(borderSide));
    }

    final borderSide =
        BorderSide(color: AFThemeExtension.of(context).borderColor);
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
  });

  final Widget child;
  final List<GridCellAccessoryBuilder> accessories;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Selector2<RegionStateNotifier, CellContainerNotifier, bool>(
      selector: (context, regionNotifier, cellNotifier) =>
          !cellNotifier.isFocus &&
          (cellNotifier.isHover || regionNotifier.onEnter && isPrimary),
      builder: (context, showAccessory, _) {
        final List<Widget> children = [child];

        if (showAccessory) {
          children.add(
            CellAccessoryContainer(accessories: accessories).positioned(
              right: GridSize.cellContentInsets.right,
            ),
          );
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (p) =>
              CellContainerNotifier.of(context, listen: false).isHover = true,
          onExit: (p) =>
              CellContainerNotifier.of(context, listen: false).isHover = false,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: children,
          ),
        );
      },
    );
  }
}

class CellContainerNotifier extends ChangeNotifier {
  bool _isFocus = false;
  bool _onEnter = false;

  set isFocus(bool value) {
    if (_isFocus != value) {
      _isFocus = value;
      notifyListeners();
    }
  }

  set isHover(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get isFocus => _isFocus;

  bool get isHover => _onEnter;

  static CellContainerNotifier of(BuildContext context, {bool listen = true}) {
    return Provider.of<CellContainerNotifier>(context, listen: listen);
  }
}
