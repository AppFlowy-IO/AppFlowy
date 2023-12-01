import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class OptionColorList extends StatelessWidget {
  const OptionColorList({
    super.key,
    this.selectedColor,
    required this.onSelectedColor,
  });

  final SelectOptionColorPB? selectedColor;
  final void Function(SelectOptionColorPB color) onSelectedColor;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: SelectOptionColorPB.values.map(
        (colorPB) {
          final color = colorPB.toColor(context);
          final isSelected = selectedColor?.value == colorPB.value;
          return GestureDetector(
            onTap: () => onSelectedColor(colorPB),
            child: Container(
              margin: const EdgeInsets.all(
                8.0,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: Corners.s12Border,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xff00C6F1)
                      : Theme.of(context).dividerColor,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const FlowySvg(
                      FlowySvgs.blue_check_s,
                      size: Size.square(28.0),
                      blendMode: null,
                    )
                  : null,
            ),
          );
        },
      ).toList(),
    );
  }
}
