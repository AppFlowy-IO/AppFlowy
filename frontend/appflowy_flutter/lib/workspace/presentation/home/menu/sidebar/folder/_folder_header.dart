import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FolderHeader extends StatefulWidget {
  const FolderHeader({
    super.key,
    required this.title,
    required this.onPressed,
    required this.onAdded,
  });

  final String title;
  final VoidCallback onPressed;
  final void Function(String name) onAdded;

  @override
  State<FolderHeader> createState() => _FolderHeaderState();
}

class _FolderHeaderState extends State<FolderHeader> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    const iconSize = 26.0;
    const textPadding = 4.0;
    return MouseRegion(
      onEnter: (event) => setState(() => onHover = true),
      onExit: (event) => setState(() => onHover = false),
      child: Row(
        children: [
          FlowyTextButton(
            widget.title,
            tooltip: LocaleKeys.sideBar_clickToHidePersonal.tr(),
            constraints: const BoxConstraints(
              minHeight: iconSize + textPadding * 2,
            ),
            padding: const EdgeInsets.all(textPadding),
            fillColor: Colors.transparent,
            onPressed: widget.onPressed,
          ),
          if (onHover) ...[
            const Spacer(),
            FlowyIconButton(
              tooltipText: LocaleKeys.sideBar_addAPage.tr(),
              hoverColor: Theme.of(context).colorScheme.secondaryContainer,
              iconPadding: const EdgeInsets.all(2),
              height: iconSize,
              width: iconSize,
              icon: const FlowySvg(FlowySvgs.add_s),
              onPressed: () {
                widget.onAdded('');
              },
            ),
          ],
        ],
      ),
    );
  }
}
