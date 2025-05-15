import 'package:appflowy/features/share/presentation/widgets/share_with_user_widget.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ShareTab extends StatelessWidget {
  const ShareTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VSpace(18),
        ShareWithUserWidget(),
        VSpace(2),
      ],
    );
  }
}
