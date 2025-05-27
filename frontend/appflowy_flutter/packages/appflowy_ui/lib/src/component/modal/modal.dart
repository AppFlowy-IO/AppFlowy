import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

export 'dimension.dart';

class AFModal extends StatelessWidget {
  const AFModal({
    super.key,
    this.constraints = const BoxConstraints(),
    this.backgroundColor,
    required this.child,
  });

  final BoxConstraints constraints;
  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.xl),
        child: ConstrainedBox(
          constraints: constraints,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: theme.shadow.medium,
              borderRadius: BorderRadius.circular(theme.borderRadius.xl),
              color: backgroundColor ?? theme.surfaceColorScheme.primary,
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class AFModalHeader extends StatelessWidget {
  const AFModalHeader({
    super.key,
    required this.leading,
    this.trailing = const [],
  });

  final Widget leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: theme.spacing.xl,
        left: theme.spacing.xxl,
        right: theme.spacing.xxl,
      ),
      child: Row(
        spacing: theme.spacing.s,
        children: [
          Expanded(child: leading),
          ...trailing,
        ],
      ),
    );
  }
}

class AFModalFooter extends StatelessWidget {
  const AFModalFooter({
    super.key,
    this.leading = const [],
    this.trailing = const [],
  });

  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: theme.spacing.xl,
        left: theme.spacing.xxl,
        right: theme.spacing.xxl,
      ),
      child: Row(
        spacing: theme.spacing.l,
        children: [
          ...leading,
          Spacer(),
          ...trailing,
        ],
      ),
    );
  }
}

class AFModalBody extends StatelessWidget {
  const AFModalBody({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.l,
        horizontal: theme.spacing.xxl,
      ),
      child: child,
    );
  }
}
