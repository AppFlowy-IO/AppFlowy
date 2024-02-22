import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/more/font_size_slider.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentMoreButton extends StatelessWidget {
  const DocumentMoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ViewInfoBloc>(),
      child: BlocBuilder<ViewInfoBloc, ViewInfoState>(
        builder: (context, state) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 400)),
            offset: const Offset(0, 30),
            popupBuilder: (_) {
              final actions = [
                AppFlowyPopover(
                  direction: PopoverDirection.leftWithCenterAligned,
                  constraints:
                      const BoxConstraints(maxHeight: 40, maxWidth: 240),
                  offset: const Offset(-10, 0),
                  popupBuilder: (context) {
                    return BlocBuilder<DocumentAppearanceCubit,
                        DocumentAppearance>(
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
                ),
                if (state.documentCounters != null) ...[
                  MoreActionFooter(documentCounters: state.documentCounters!),
                ],
              ];

              return ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: actions.length,
                separatorBuilder: (_, __) => const VSpace(4),
                physics: StyledScrollPhysics(),
                itemBuilder: (_, index) => actions[index],
              );
            },
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
          );
        },
      ),
    );
  }
}

class MoreActionFooter extends StatelessWidget {
  const MoreActionFooter({super.key, required this.documentCounters});

  final Counters documentCounters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 4),
          const VSpace(2),
          FlowyText(
            LocaleKeys.moreAction_wordCount.tr(
              args: [
                documentCounters.wordCount.toString(),
              ],
            ),
            color: Theme.of(context).hintColor,
            fontSize: 10,
          ),
          const VSpace(2),
          FlowyText(
            LocaleKeys.moreAction_charCount.tr(
              args: [
                documentCounters.charCount.toString(),
              ],
            ),
            color: Theme.of(context).hintColor,
            fontSize: 10,
          ),
        ],
      ),
    );
  }
}
