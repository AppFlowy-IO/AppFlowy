import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
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
    return Row(
      children: [
        Expanded(
          child: FlowyButton(
            text: FlowyText.medium(
              widget.title,
              fontSize: 16.0,
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2.0),
            expandText: false,
            iconPadding: 2,
            mainAxisAlignment: MainAxisAlignment.start,
            rightIcon: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _turns,
              child: const FlowySvg(
                FlowySvgs.m_spaces_expand_s,
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
          height: HomeSpaceViewSizes.mViewButtonDimension,
          width: HomeSpaceViewSizes.mViewButtonDimension,
          icon: const FlowySvg(
            FlowySvgs.m_space_add_s,
          ),
          onPressed: widget.onAdded,
        ),
      ],
    );
  }
}
