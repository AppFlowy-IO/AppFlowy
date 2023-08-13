import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/style_widget/icon_button.dart';

/// ··· button beside the view name
class ViewMoreActionButton extends StatelessWidget {
  const ViewMoreActionButton({
    super.key,
    required this.onPressed,
  });

  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      hoverColor: Colors.transparent,
      iconPadding: const EdgeInsets.all(2),
      width: 26,
      icon: const FlowySvg(FlowySvgs.details_s),
      onPressed: onPressed,
    );
  }
}
