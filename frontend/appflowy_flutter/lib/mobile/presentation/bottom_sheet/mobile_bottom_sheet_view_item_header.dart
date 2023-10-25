import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileViewItemBottomSheetHeader extends StatelessWidget {
  const MobileViewItemBottomSheetHeader({
    super.key,
    required this.view,
    required this.showBackButton,
    required this.onBack,
  });

  final ViewPB view;
  final bool showBackButton;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // back button,
        showBackButton
            ? InkWell(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 24.0,
                  ),
                ),
              )
            : const HSpace(40.0),
        // title
        FlowyText.regular(
          view.name,
          fontSize: 16.0,
        ),
        // placeholder, ensure the title is centered
        const HSpace(40.0),
      ],
    );
  }
}
