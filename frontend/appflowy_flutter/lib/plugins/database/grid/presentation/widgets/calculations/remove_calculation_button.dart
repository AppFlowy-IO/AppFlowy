import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

class RemoveCalculationButton extends StatelessWidget {
  const RemoveCalculationButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: const FlowyText.medium(
          'None',
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          onTap();
          PopoverContainer.of(context).close();
        },
      ),
    );
  }
}
