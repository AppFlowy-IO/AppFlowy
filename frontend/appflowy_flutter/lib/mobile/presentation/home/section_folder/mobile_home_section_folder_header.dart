import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

@visibleForTesting
const Key mobileCreateNewPageButtonKey = Key('mobileCreateNewPageButtonKey');

class MobileSectionFolderHeader extends StatefulWidget {
  const MobileSectionFolderHeader({
    super.key,
    required this.title,
    required this.onPressed,
    required this.onAdded,
    required this.isExpanded,
  });

  final String title;
  final VoidCallback onPressed;
  final VoidCallback onAdded;
  final bool isExpanded;

  @override
  State<MobileSectionFolderHeader> createState() =>
      _MobileSectionFolderHeaderState();
}

class _MobileSectionFolderHeaderState extends State<MobileSectionFolderHeader> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    const iconSize = 32.0;
    return Row(
      children: [
        Expanded(
          child: FlowyButton(
            text: FlowyText.semibold(
              widget.title,
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
        FlowyIconButton(
          key: mobileCreateNewPageButtonKey,
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          iconPadding: const EdgeInsets.all(2),
          height: iconSize,
          width: iconSize,
          icon: const FlowySvg(
            FlowySvgs.add_s,
            size: Size.square(iconSize),
          ),
          onPressed: widget.onAdded,
        ),
      ],
    );
  }
}
