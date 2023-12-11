import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/more/font_size_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentMoreButton extends StatelessWidget {
  const DocumentMoreButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 320),
      offset: const Offset(0, 30),
      child: FlowyTooltip(
        message: LocaleKeys.moreAction_moreOptions.tr(),
        child: FlowyHover(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FlowySvg(
              FlowySvgs.details_s,
              size: const Size(18, 18),
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
      popupBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocProvider.value(
                value: context.read<DocumentAppearanceCubit>(),
                child: const FontSizeSwitcher(),
              ),
            ],
          ),
        );
      },
    );
  }
}
