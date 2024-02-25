import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

class DeleteViewAction extends StatelessWidget {
  const DeleteViewAction({super.key, required this.view, this.mutex});

  final ViewPB view;
  final PopoverMutex? mutex;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      onTap: () {
        getIt<ViewBloc>(param1: view).add(const ViewEvent.delete());
        mutex?.close();
      },
      text: FlowyText.regular(
        LocaleKeys.moreAction_deleteView.tr(),
        color: AFThemeExtension.of(context).textColor,
      ),
      leftIcon: FlowySvg(
        FlowySvgs.delete_s,
        color: Theme.of(context).iconTheme.color,
        size: const Size.square(18),
      ),
      leftIconSize: const Size(18, 18),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
    );
  }
}
