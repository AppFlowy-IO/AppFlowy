import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ViewActionType {
  delete,
  duplicate;

  String get label => switch (this) {
        ViewActionType.delete => LocaleKeys.moreAction_deleteView.tr(),
        ViewActionType.duplicate => LocaleKeys.moreAction_duplicateView.tr(),
      };

  FlowySvgData get icon => switch (this) {
        ViewActionType.delete => FlowySvgs.delete_s,
        ViewActionType.duplicate => FlowySvgs.m_duplicate_s,
      };

  ViewEvent get actionEvent => switch (this) {
        ViewActionType.delete => const ViewEvent.delete(),
        ViewActionType.duplicate => const ViewEvent.duplicate(),
      };
}

class ViewAction extends StatelessWidget {
  const ViewAction({
    super.key,
    required this.type,
    required this.view,
    this.mutex,
  });

  final ViewActionType type;
  final ViewPB view;
  final PopoverMutex? mutex;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      onTap: () {
        context.read<ViewBloc>().add(type.actionEvent);
        mutex?.close();
      },
      text: FlowyText.regular(
        type.label,
        color: AFThemeExtension.of(context).textColor,
      ),
      leftIcon: FlowySvg(
        type.icon,
        color: Theme.of(context).iconTheme.color,
        size: const Size.square(18),
      ),
      leftIconSize: const Size(18, 18),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
    );
  }
}
