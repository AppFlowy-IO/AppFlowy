import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/view_actions_top_bar/view_actions.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DatabaseMoreAction extends StatefulWidget {
  const DatabaseMoreAction({super.key, required this.view});

  final ViewPB view;

  @override
  State<DatabaseMoreAction> createState() => _DatabaseMoreActionState();
}

class _DatabaseMoreActionState extends State<DatabaseMoreAction> {
  late final UserDateFormatPB dateFormat;
  final popoverMutex = PopoverMutex();

  @override
  void initState() {
    super.initState();
    dateFormat = context.read<AppearanceSettingsCubit>().state.dateFormat;
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ViewInfoBloc>(),
      child: BlocBuilder<ViewInfoBloc, ViewInfoState>(
        builder: (context, state) {
          return AppFlowyPopover(
            mutex: popoverMutex,
            constraints: BoxConstraints.loose(const Size(200, 400)),
            offset: const Offset(0, 30),
            popupBuilder: (_) {
              final actions = [
                DuplicateViewAction(view: widget.view, mutex: popoverMutex),
                DeleteViewAction(view: widget.view, mutex: popoverMutex),
                _MoreActionFooter(
                  dateFormat: dateFormat,
                  createdAt: state.createdAt,
                ),
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

class _MoreActionFooter extends StatelessWidget {
  const _MoreActionFooter({
    required this.dateFormat,
    this.createdAt,
  });

  final UserDateFormatPB dateFormat;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    if (createdAt == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (createdAt != null) ...[
            const Divider(height: 2),
            const VSpace(2),
            FlowyText(
              LocaleKeys.moreAction_createdAt.tr(
                args: [
                  dateFormat.formatDate(createdAt!, false),
                ],
              ),
              color: Theme.of(context).hintColor,
              fontSize: 10,
            ),
          ],
        ],
      ),
    );
  }
}
