import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: onTap,
      child: const Icon(Icons.arrow_back_ios_new),
    );
  }
}

class AppBarCancelButton extends StatelessWidget {
  const AppBarCancelButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: onTap,
      child: FlowyText(
        LocaleKeys.button_cancel.tr(),
      ),
    );
  }
}

class AppBarMoreButton extends StatelessWidget {
  const AppBarMoreButton({
    super.key,
    required this.onTap,
  });

  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: () => onTap(context),
      child: const Icon(
        // replace with flowy icon
        Icons.more_horiz_sharp,
      ),
    );
  }
}

class AppBarButton extends StatelessWidget {
  const AppBarButton({
    super.key,
    this.extent = 16.0,
    required this.onTap,
    required this.child,
  });

  // used to extend the hit area of the more button
  final double extent;

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      enableFeedback: true,
      borderRadius: BorderRadius.circular(28),
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(extent),
        child: child,
      ),
    );
  }
}
