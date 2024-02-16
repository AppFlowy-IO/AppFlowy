import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: onTap ?? () => Navigator.pop(context),
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
      onTap: onTap ?? () => Navigator.pop(context),
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
      onTap: onTap ?? () => Navigator.pop(context),
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
      isActionButton: true,
      onTap: onTap,
      child: FlowyText(
        LocaleKeys.button_Done.tr(),
        color: Theme.of(context).colorScheme.primary,
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
      isActionButton: true,
      onTap: () => onTap(context),
      child: const FlowySvg(FlowySvgs.three_dots_s),
    );
  }
}

class AppBarButton extends StatelessWidget {
  const AppBarButton({
    super.key,
    this.isActionButton = false,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool isActionButton;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: 12.0,
          bottom: 12.0,
          left: 12.0,
          right: isActionButton ? 12.0 : 8.0,
        ),
        child: child,
      ),
    );
  }
}
