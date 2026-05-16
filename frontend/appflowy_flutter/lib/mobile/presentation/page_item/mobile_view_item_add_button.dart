import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileViewAddButton extends StatelessWidget {
  const MobileViewAddButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: HomeSpaceViewSizes.mViewButtonDimension,
      height: HomeSpaceViewSizes.mViewButtonDimension,
      icon: const FlowySvg(
        FlowySvgs.m_space_add_s,
      ),
      onPressed: onPressed,
    );
  }
}

class MobileViewMoreButton extends StatelessWidget {
  const MobileViewMoreButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: HomeSpaceViewSizes.mViewButtonDimension,
      height: HomeSpaceViewSizes.mViewButtonDimension,
      icon: const FlowySvg(
        FlowySvgs.m_space_more_s,
      ),
      onPressed: onPressed,
    );
  }
}
