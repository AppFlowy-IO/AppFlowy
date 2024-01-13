import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class DocumentStarButton extends StatefulWidget {
  const DocumentStarButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  DocumentStarButtonState createState() => DocumentStarButtonState();
}

class DocumentStarButtonState extends State<DocumentStarButton> {
  bool isStarred = false;

  @override
  void initState() {
    super.initState();
    isStarred = widget.view.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.moreAction_moreOptions.tr(),
      child: FlowyHover(
        child: GestureDetector(
          onTap: () {
            setState(() {
              print("favorte button clicked");
              // add the logic to toggle the favorite
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FlowySvg(
              isStarred ? FlowySvgs.favorite_s : FlowySvgs.unfavorite_s,
              size: const Size(18, 18),
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}
