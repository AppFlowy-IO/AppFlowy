import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/common_view_action.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/font_size_action.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/view_meta_info.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoreViewActions extends StatefulWidget {
  const MoreViewActions({
    super.key,
    required this.view,
    this.isDocument = true,
  });

  /// The view to show the actions for.
  final ViewPB view;

  /// If false the view is a Database, otherwise it is a Document.
  final bool isDocument;

  @override
  State<MoreViewActions> createState() => _MoreViewActionsState();
}

class _MoreViewActionsState extends State<MoreViewActions> {
  late final List<Widget> viewActions;
  final popoverMutex = PopoverMutex();

  @override
  void initState() {
    super.initState();
    viewActions = ViewActionType.values
        .map(
          (type) => ViewAction(
            type: type,
            view: widget.view,
            mutex: popoverMutex,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearanceSettings = context.watch<AppearanceSettingsCubit>().state;
    final dateFormat = appearanceSettings.dateFormat;
    final timeFormat = appearanceSettings.timeFormat;

    return BlocBuilder<ViewInfoBloc, ViewInfoState>(
      builder: (context, state) {
        return AppFlowyPopover(
          mutex: popoverMutex,
          constraints: BoxConstraints.loose(const Size(215, 400)),
          offset: const Offset(0, 30),
          popupBuilder: (_) {
            final actions = [
              if (widget.isDocument) ...[
                const FontSizeAction(),
                const Divider(height: 4),
              ],
              ...viewActions,
              if (state.documentCounters != null ||
                  state.createdAt != null) ...[
                const Divider(height: 4),
                ViewMetaInfo(
                  dateFormat: dateFormat,
                  timeFormat: timeFormat,
                  documentCounters: state.documentCounters,
                  createdAt: state.createdAt,
                ),
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
              style: HoverStyle(
                foregroundColorOnHover: Theme.of(context).colorScheme.onPrimary,
              ),
              builder: (context, isHovering) => Padding(
                padding: const EdgeInsets.all(6),
                child: FlowySvg(
                  FlowySvgs.three_dots_vertical_s,
                  size: const Size.square(16),
                  color: isHovering
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
