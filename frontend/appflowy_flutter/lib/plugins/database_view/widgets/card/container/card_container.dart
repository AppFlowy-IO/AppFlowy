import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'accessory.dart';

class RowCardContainer extends StatelessWidget {
  final Widget child;
  final CardAccessoryBuilder? accessoryBuilder;
  final bool Function()? buildAccessoryWhen;
  final void Function(BuildContext) openCard;
  final void Function(AccessoryType) openAccessory;
  const RowCardContainer({
    required this.child,
    required this.openCard,
    required this.openAccessory,
    this.accessoryBuilder,
    this.buildAccessoryWhen,
    Key? key,
  }) : super(key: key);

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

          if (accessoryBuilder != null && shouldBuildAccessory) {
            final accessories = accessoryBuilder!(context);
            if (accessories.isNotEmpty) {
              container = _CardEnterRegion(
                accessories: accessories,
                onTapAccessory: openAccessory,
                child: container,
              );
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openCard(context),
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
  final Widget child;
  final List<CardAccessory> accessories;
  final void Function(AccessoryType) onTapAccessory;
  const _CardEnterRegion({
    required this.child,
    required this.accessories,
    required this.onTapAccessory,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<_CardContainerNotifier, bool>(
      selector: (context, notifier) => notifier.onEnter,
      builder: (context, onEnter, _) {
        final List<Widget> children = [child];
        if (onEnter) {
          children.add(
            Positioned(
              top: 8.0,
              right: 8.0,
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
  bool _onEnter = false;

  _CardContainerNotifier();

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}
