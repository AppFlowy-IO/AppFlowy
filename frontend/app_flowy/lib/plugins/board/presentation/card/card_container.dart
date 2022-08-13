import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class BoardCardContainer extends StatelessWidget {
  final Widget child;
  final CardAccessoryBuilder? accessoryBuilder;
  const BoardCardContainer({
    required this.child,
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
          return Padding(
            padding: const EdgeInsets.all(8),
            child: container,
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
            alignment: AlignmentDirectional.center,
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
