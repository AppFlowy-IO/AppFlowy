import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/more/font_size_slider.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class DuplicateViewAction extends StatelessWidget {
  const DuplicateViewAction({super.key, required this.view, this.mutex});

  final ViewPB view;
  final PopoverMutex? mutex;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      onTap: () {
        getIt<ViewBloc>(param1: view).add(const ViewEvent.duplicate());
        mutex?.close();
      },
      text: FlowyText.regular(
        LocaleKeys.moreAction_duplicateView.tr(),
        color: AFThemeExtension.of(context).textColor,
      ),
      leftIcon: FlowySvg(
        FlowySvgs.copy_s,
        color: Theme.of(context).iconTheme.color,
        size: const Size.square(18),
      ),
      leftIconSize: const Size(18, 18),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
    );
  }
}

class FontSizeAction extends StatelessWidget {
  const FontSizeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.leftWithCenterAligned,
      constraints: const BoxConstraints(maxHeight: 40, maxWidth: 240),
      offset: const Offset(-10, 0),
      popupBuilder: (context) {
        return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
          builder: (context, state) {
            return FontSizeStepper(
              minimumValue: 10,
              maximumValue: 24,
              value: state.fontSize,
              divisions: 8,
              onChanged: (newFontSize) {
                context
                    .read<DocumentAppearanceCubit>()
                    .syncFontSize(newFontSize);
              },
            );
          },
        );
      },
      child: FlowyButton(
        text: FlowyText.regular(
          LocaleKeys.moreAction_fontSize.tr(),
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: Icon(
          Icons.format_size_sharp,
          color: Theme.of(context).iconTheme.color,
          size: 18,
        ),
        leftIconSize: const Size(18, 18),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
      ),
    );
  }
}
