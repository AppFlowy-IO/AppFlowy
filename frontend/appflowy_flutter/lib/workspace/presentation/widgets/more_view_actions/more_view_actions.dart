import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/common_view_action.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/font_size_action.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/view_meta_info.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
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
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewInfoBloc, ViewInfoState>(
      builder: (context, state) {
        return AppFlowyPopover(
          mutex: popoverMutex,
          constraints: const BoxConstraints(maxWidth: 220),
          offset: const Offset(0, 42),
          popupBuilder: (_) => _buildPopup(state),
          child: const _ThreeDots(),
        );
      },
    );
  }

  Widget _buildPopup(ViewInfoState state) {
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    final userProfile = userWorkspaceBloc.userProfile;
    final workspaceId =
        userWorkspaceBloc.state.currentWorkspace?.workspaceId ?? '';
    final actions = _buildActions(state);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ViewBloc(view: widget.view)..add(const ViewEvent.initial()),
        ),
        BlocProvider(
          create: (context) => SpaceBloc(
            userProfile: userProfile,
            workspaceId: workspaceId,
          )..add(
              const SpaceEvent.initial(openFirstPage: false),
            ),
        ),
      ],
      child: BlocBuilder<SpaceBloc, SpaceState>(
        builder: (context, state) {
          if (state.spaces.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.builder(
            key: ValueKey(state.spaces.hashCode),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: actions.length,
            physics: StyledScrollPhysics(),
            itemBuilder: (_, index) => actions[index],
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(ViewInfoState state) {
    final appearanceSettings = context.watch<AppearanceSettingsCubit>().state;
    final dateFormat = appearanceSettings.dateFormat;
    final timeFormat = appearanceSettings.timeFormat;

    final viewMoreActionTypes = [
      if (widget.isDocument) ViewMoreActionType.divider,
      ViewMoreActionType.duplicate,
      ViewMoreActionType.moveTo,
      ViewMoreActionType.delete,
      ViewMoreActionType.divider,
    ];

    final actions = [
      if (widget.isDocument) ...[
        const FontSizeAction(),
      ],
      ...viewMoreActionTypes.map(
        (type) => ViewAction(
          type: type,
          view: widget.view,
          mutex: popoverMutex,
        ),
      ),
      if (state.documentCounters != null || state.createdAt != null) ...[
        ViewMetaInfo(
          dateFormat: dateFormat,
          timeFormat: timeFormat,
          documentCounters: state.documentCounters,
          createdAt: state.createdAt,
        ),
        const VSpace(4.0),
      ],
    ];
    return actions;
  }
}

class _ThreeDots extends StatelessWidget {
  const _ThreeDots();

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.moreAction_moreOptions.tr(),
      child: FlowyHover(
        style: HoverStyle(
          foregroundColorOnHover: Theme.of(context).colorScheme.onPrimary,
        ),
        builder: (context, isHovering) => Padding(
          padding: const EdgeInsets.all(6),
          child: FlowySvg(
            FlowySvgs.three_dots_s,
            size: const Size.square(18),
            color: isHovering
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}
