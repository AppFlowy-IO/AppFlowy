import 'package:app_flowy/plugins/document/document.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:provider/provider.dart';

class FontSizeSwitcher extends StatefulWidget {
  const FontSizeSwitcher({
    super.key,
    // required this.documentStyle,
  });

  // final DocumentStyle documentStyle;

  @override
  State<FontSizeSwitcher> createState() => _FontSizeSwitcherState();
}

class _FontSizeSwitcherState extends State<FontSizeSwitcher> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FlowyText.semibold(LocaleKeys.moreAction_fontSize),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFontSizeSwitchButton(LocaleKeys.moreAction_small, 12.0),
            _buildFontSizeSwitchButton(LocaleKeys.moreAction_medium, 14.0),
            _buildFontSizeSwitchButton(LocaleKeys.moreAction_large, 18.0),
          ],
        )
      ],
    );
  }

  Widget _buildFontSizeSwitchButton(String name, double fontSize) {
    return Center(
      child: TextButton(
        onPressed: () {
          final x = Provider.of<DocumentStyle>(context, listen: false);
          x;
          Provider.of<DocumentStyle>(context, listen: false).fontSize =
              fontSize;
        },
        child: Text(
          name,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
