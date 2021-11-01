import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/buttons/base_styled_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DocBanner extends StatelessWidget {
  final void Function() onRestore;
  final void Function() onDelete;
  const DocBanner({required this.onRestore, required this.onDelete, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    // [[Row]] CrossAxisAlignment vs mainAxisAlignment
    // https://stackoverflow.com/questions/53850149/flutter-crossaxisalignment-vs-mainaxisalignment
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        color: theme.main1,
        height: 60,
        child: Row(
          children: [
            const FlowyText.medium('This page is in Trash', color: Colors.white),
            const HSpace(20),
            BaseStyledButton(
                minWidth: 160,
                minHeight: 40,
                contentPadding: EdgeInsets.zero,
                bgColor: Colors.transparent,
                hoverColor: theme.main2,
                downColor: theme.main1,
                outlineColor: Colors.white,
                borderRadius: Corners.s8Border,
                child: const FlowyText.medium('Restore page', color: Colors.white, fontSize: 14),
                onPressed: onRestore),
            const HSpace(20),
            BaseStyledButton(
                minWidth: 220,
                minHeight: 40,
                contentPadding: EdgeInsets.zero,
                bgColor: Colors.transparent,
                hoverColor: theme.main2,
                downColor: theme.main1,
                outlineColor: Colors.white,
                borderRadius: Corners.s8Border,
                child: const FlowyText.medium('Delete permanently', color: Colors.white, fontSize: 14),
                onPressed: onDelete),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}
