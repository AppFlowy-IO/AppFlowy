import 'package:app_flowy/plugins/document/presentation/more/font_size_switcher.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class DocumentMoreButton extends StatelessWidget {
  const DocumentMoreButton({
    Key? key,
    // required this.documentStyle,
  }) : super(key: key);

  // final DocumentStyle documentStyle;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 1,
            enabled: false,
            child: FontSizeSwitcher(
                // documentStyle: documentStyle,
                ),
          )
        ];
      },
      child: svgWithSize('editor/details', const Size(18, 18)),
    );
  }
}
