import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class BoardCardContainer extends StatelessWidget {
  final Widget child;
  final CardAccessoryBuilder? accessoryBuilder;
  final void Function(BuildContext) onTap;
  const BoardCardContainer({
    required this.child,
    required this.onTap,
    this.accessoryBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _CardContainerNotifier(),
      child: Consumer<_CardContainerNotifier>(
        builder: (context, notifier, _) {
          Widget container = Center(child: child);
          if (accessoryBuilder != null) {
            final accessories = accessoryBuilder!(context);
            if (accessories.isNotEmpty) {
              container = _CardEnterRegion(
                child: container,
                accessories: accessories,
              );
            }
          }

          return GestureDetector(
            onTap: () => onTap(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 30),
                child: container,
              ),
            ),
          );
        },
      ),
    );
  }
}

abstract class CardAccessory implements Widget {
  void onTap(BuildContext context);
}

typedef CardAccessoryBuilder = List<CardAccessory> Function(
  BuildContext buildContext,
);

class CardAccessoryContainer extends StatelessWidget {
  final List<CardAccessory> accessories;
  const CardAccessoryContainer({required this.accessories, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppTheme>();
    final children = accessories.map((accessory) {
      final hover = FlowyHover(
        style: HoverStyle(
          hoverColor: theme.hover,
          backgroundColor: theme.surface,
        ),
        builder: (_, onHover) => Container(
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: _makeBoxDecoration(context),
          child: accessory,
        ),
      );
      return GestureDetector(
        child: hover,
        behavior: HitTestBehavior.opaque,
        onTap: () => accessory.onTap(context),
      );
    }).toList();

    return Wrap(children: children, spacing: 6);
  }
}

BoxDecoration _makeBoxDecoration(BuildContext context) {
  final theme = context.read<AppTheme>();
  final borderSide = BorderSide(color: theme.shader6, width: 1.0);
  return BoxDecoration(
    color: theme.surface,
    border: Border.fromBorderSide(borderSide),
    boxShadow: [
      BoxShadow(
          color: theme.shader6,
          spreadRadius: 0,
          blurRadius: 2,
          offset: Offset.zero)
    ],
    borderRadius: const BorderRadius.all(Radius.circular(6)),
  );
}

class _CardEnterRegion extends StatelessWidget {
  final Widget child;
  final List<CardAccessory> accessories;
  const _CardEnterRegion(
      {required this.child, required this.accessories, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<_CardContainerNotifier, bool>(
      selector: (context, notifier) => notifier.onEnter,
      builder: (context, onEnter, _) {
        List<Widget> children = [child];
        if (onEnter) {
          children.add(CardAccessoryContainer(accessories: accessories)
              .positioned(right: 0));
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
          )),
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
