import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class BoardCardContainer extends StatelessWidget {
  final Widget child;
  final CardAccessoryBuilder? accessoryBuilder;
  final bool Function()? buildAccessoryWhen;
  final void Function(BuildContext) onTap;
  const BoardCardContainer({
    required this.child,
    required this.onTap,
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
                child: container,
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
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => accessory.onTap(context),
        child: _wrapHover(theme, accessory),
      );
    }).toList();
    return _wrapDecoration(context, Row(children: children));
  }

  FlowyHover _wrapHover(AppTheme theme, CardAccessory accessory) {
    return FlowyHover(
      style: HoverStyle(
        hoverColor: theme.hover,
        backgroundColor: theme.surface,
        borderRadius: BorderRadius.zero,
      ),
      builder: (_, onHover) => SizedBox(
        width: 24,
        height: 24,
        child: accessory,
      ),
    );
  }

  Widget _wrapDecoration(BuildContext context, Widget child) {
    final theme = context.read<AppTheme>();
    final borderSide = BorderSide(color: theme.shader6, width: 1.0);
    final decoration = BoxDecoration(
      color: Colors.transparent,
      border: Border.fromBorderSide(borderSide),
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: decoration,
      child: child,
    );
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
          children.add(CardAccessoryContainer(
            accessories: accessories,
          ).positioned(right: 0));
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
