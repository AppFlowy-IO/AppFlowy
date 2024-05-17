import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class FavoritePinAction extends StatelessWidget {
  const FavoritePinAction({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: 'Remove from sidebar',
      child: FlowyIconButton(
        width: 24,
        icon: const FlowySvg(FlowySvgs.favorite_section_pin_s),
        onPressed: () {},
      ),
    );
  }
}
