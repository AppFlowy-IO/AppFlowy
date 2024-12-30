import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_buttons.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader({
    super.key,
    this.title,
    this.onClose,
    this.onDone,
  });

  final String? title;
  final VoidCallback? onClose;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (onClose != null)
          Positioned(
            left: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BottomSheetCloseButton(
                onTap: onClose,
              ),
            ),
          ),
        if (title != null)
          Align(
            child: FlowyText.medium(
              title!,
              fontSize: 16,
            ),
          ),
        if (onDone != null)
          Align(
            alignment: Alignment.centerRight,
            child: BottomSheetDoneButton(
              onDone: onDone,
            ),
          ),
      ],
    );
  }
}
