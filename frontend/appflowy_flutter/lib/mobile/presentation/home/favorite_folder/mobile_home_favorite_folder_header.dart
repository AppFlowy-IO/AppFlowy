import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileFavoriteFolderHeader extends StatefulWidget {
  const MobileFavoriteFolderHeader({
    super.key,
    required this.onPressed,
    required this.onAdded,
    required this.isExpanded,
  });

  final VoidCallback onPressed;
  final VoidCallback onAdded;
  final bool isExpanded;

  @override
  State<MobileFavoriteFolderHeader> createState() =>
      _MobileFavoriteFolderHeaderState();
}

class _MobileFavoriteFolderHeaderState
    extends State<MobileFavoriteFolderHeader> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyButton(
            text: FlowyText.semibold(
              LocaleKeys.sideBar_favorites.tr(),
              fontSize: 20.0,
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            expandText: false,
            mainAxisAlignment: MainAxisAlignment.start,
            rightIcon: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _turns,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
              ),
            ),
            onTap: () {
              setState(() {
                _turns = widget.isExpanded ? -0.25 : 0;
              });
              widget.onPressed();
            },
          ),
        ),
      ],
    );
  }
}
