import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    this.onTap,
    this.padding,
  });

  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: (_) => (onTap ?? () => Navigator.pop(context)).call(),
      padding: padding,
      child: const FlowySvg(
        FlowySvgs.m_app_bar_back_s,
      ),
    );
  }
}

class AppBarCloseButton extends StatelessWidget {
  const AppBarCloseButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: (_) => (onTap ?? () => Navigator.pop(context)).call(),
      child: const FlowySvg(
        FlowySvgs.m_app_bar_close_s,
      ),
    );
  }
}

class AppBarCancelButton extends StatelessWidget {
  const AppBarCancelButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: (_) => (onTap ?? () => Navigator.pop(context)).call(),
      child: FlowyText(
        LocaleKeys.button_cancel.tr(),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class AppBarDoneButton extends StatelessWidget {
  const AppBarDoneButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: (_) => onTap(),
      padding: const EdgeInsets.all(12),
      child: FlowyText(
        LocaleKeys.button_done.tr(),
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.right,
      ),
    );
  }
}

class AppBarSaveButton extends StatelessWidget {
  const AppBarSaveButton({
    super.key,
    required this.onTap,
    this.enable = true,
    this.padding = const EdgeInsets.all(12),
  });

  final VoidCallback onTap;
  final bool enable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: (_) {
        if (enable) {
          onTap();
        }
      },
      padding: padding,
      child: FlowyText(
        LocaleKeys.button_save.tr(),
        color: enable
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.right,
      ),
    );
  }
}

class AppBarFilledDoneButton extends StatelessWidget {
  const AppBarFilledDoneButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          enableFeedback: true,
          backgroundColor: Theme.of(context).primaryColor,
        ),
        onPressed: onTap,
        child: FlowyText.medium(
          LocaleKeys.button_done.tr(),
          fontSize: 16,
          color: Theme.of(context).colorScheme.onPrimary,
          overflow: TextOverflow.ellipsis,
        ),
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
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: const FlowySvg(FlowySvgs.three_dots_s),
    );
  }
}

class AppBarButton extends StatelessWidget {
  const AppBarButton({
    super.key,
    required this.onTap,
    required this.child,
    this.padding,
  });

  final void Function(BuildContext context) onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(context),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
