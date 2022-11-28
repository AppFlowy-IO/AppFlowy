import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/plugins/document/presentation/more/font_size_switcher.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DocumentMoreButton extends StatelessWidget {
  const DocumentMoreButton({
    Key? key,
    // required this.documentStyle,
  }) : super(key: key);

  // final DocumentStyle documentStyle;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 30),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: 1,
            enabled: false,
            child: ChangeNotifierProvider.value(
              value: context.read<DocumentStyle>(),
              child: const FontSizeSwitcher(),
            ),
          )
        ];
      },
      child: svgWithSize('editor/details', const Size(18, 18)),
    );
  }
}
