import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'accessory.dart';

class RowCardContainer extends StatelessWidget {
  const RowCardContainer({
    super.key,
    required this.child,
    required this.onTap,
    required this.openAccessory,
    required this.accessories,
    this.buildAccessoryWhen,
    this.onShiftTap,
  });

  final Widget child;
  final void Function(BuildContext) onTap;
  final void Function(BuildContext)? onShiftTap;
  final void Function(AccessoryType) openAccessory;
  final List<CardAccessory> accessories;
  final bool Function()? buildAccessoryWhen;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _CardContainerNotifier(),
      child: Consumer<_CardContainerNotifier>(
        builder: (context, notifier, _) {
          Widget container = Center(child: child);
          bool shouldBuildAccessory = true;
          if (buildAccessoryWhen != null) {
            shouldBuildAccessory = buildAccessoryWhen!.call();
          }

          if (shouldBuildAccessory && accessories.isNotEmpty) {
            container = _CardEnterRegion(
              accessories: accessories,
              onTapAccessory: openAccessory,
              child: container,
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (HardwareKeyboard.instance.isShiftPressed) {
                onShiftTap?.call(context);
              } else {
                onTap(context);
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 30),
              child: container,
            ),
          );
        },
      ),
    );
  }
}

class _CardEnterRegion extends StatelessWidget {
  const _CardEnterRegion({
    required this.child,
    required this.accessories,
    required this.onTapAccessory,
  });

  final Widget child;
  final List<CardAccessory> accessories;
  final void Function(AccessoryType) onTapAccessory;

  @override
  Widget build(BuildContext context) {
    return Selector<_CardContainerNotifier, bool>(
      selector: (context, notifier) => notifier.onEnter,
      builder: (context, onEnter, _) {
        final List<Widget> children = [child];
        if (onEnter) {
          children.add(
            Positioned(
              top: 10.0,
              right: 10.0,
              child: CardAccessoryContainer(
                accessories: accessories,
                onTapAccessory: onTapAccessory,
              ),
            ),
          );
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (p) =>
              Provider.of<_CardContainerNotifier>(context, listen: false)
                  .onEnter = true,
          onExit: (p) =>
              Provider.of<_CardContainerNotifier>(context, listen: false)
                  .onEnter = false,
          child: IntrinsicHeight(
            child: Stack(
              alignment: AlignmentDirectional.topEnd,
              fit: StackFit.expand,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _CardContainerNotifier extends ChangeNotifier {
  _CardContainerNotifier();

  bool _onEnter = false;

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}
