import 'package:appflowy/features/page_access_level/logic/page_access_level_bloc.dart';
import 'package:appflowy/features/share_tab/data/models/share_section_type.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view_title/view_title_bar_bloc.dart';
import 'package:appflowy/workspace/application/view_title/view_title_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/rename_view_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart'
    hide AFRolePB;
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';

// space name > ... > view_title
class ViewTitleBar extends StatelessWidget {
  const ViewTitleBar({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ViewTitleBarBloc(
            view: view,
          ),
        ),
      ],
      child: BlocBuilder<PageAccessLevelBloc, PageAccessLevelState>(
        buildWhen: (previous, current) =>
            previous.isLoadingLockStatus != current.isLoadingLockStatus,
        builder: (context, pageAccessLevelState) {
          return BlocConsumer<ViewTitleBarBloc, ViewTitleBarState>(
            listener: (context, state) {
              // update the page section type when the space permission is changed
              final spacePermission = state.ancestors
                  .firstWhereOrNull(
                    (ancestor) => ancestor.isSpace,
                  )
                  ?.spacePermission;
              if (spacePermission == null) {
                return;
              }
              final sectionType = switch (spacePermission) {
                SpacePermission.publicToAll => SharedSectionType.public,
                SpacePermission.private => SharedSectionType.private,
              };
              if (!context.read<PageAccessLevelBloc>().state.isShared) {
                context.read<PageAccessLevelBloc>().add(
                      PageAccessLevelEvent.updateSectionType(sectionType),
                    );
              }
            },
            builder: (context, state) {
              final theme = AppFlowyTheme.of(context);
              final ancestors = state.ancestors;
              if (ancestors.isEmpty) {
                return const SizedBox.shrink();
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      ..._buildViewTitles(
                        context,
                        ancestors,
                        state.isDeleted,
                        pageAccessLevelState.isEditable,
                        pageAccessLevelState,
                      ),
                      HSpace(theme.spacing.m),
                      _buildLockPageStatus(context),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLockPageStatus(BuildContext context) {
    return BlocConsumer<PageAccessLevelBloc, PageAccessLevelState>(
      listenWhen: (previous, current) =>
          previous.isLoadingLockStatus == current.isLoadingLockStatus &&
          current.isLoadingLockStatus == false,
      listener: (context, state) {
        if (state.isLocked) {
          showToastNotification(
            message: LocaleKeys.lockPage_pageLockedToast.tr(),
          );
        }
      },
      builder: (context, state) {
        if (state.isLocked) {
          return LockedPageStatus();
        } else if (!state.isLocked && state.lockCounter > 0) {
          return ReLockedPageStatus();
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<Widget> _buildViewTitles(
    BuildContext context,
    List<ViewPB> views,
    bool isDeleted,
    bool isEditable,
    PageAccessLevelState pageAccessLevelState,
  ) {
    final theme = AppFlowyTheme.of(context);

    if (isDeleted) {
      return _buildDeletedTitle(context, views.last);
    }

    // if the level is too deep, only show the last two view, the first one view and the root view
    // for example:
    // if the views are [root, view1, view2, view3, view4, view5], only show [root, view1, ..., view4, view5]
    // if the views are [root, view1, view2, view3], show [root, view1, view2, view3]
    const lowerBound = 2;
    final upperBound = views.length - 2;
    bool hasAddedEllipsis = false;
    final children = <Widget>[];

    if (views.length <= 1) {
      return [];
    }

    // remove the space from views if the current user role is a guest
    final myRole =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.role;
    if (myRole == AFRolePB.Guest) {
      views = views.where((view) => !view.isSpace).toList();
    }

    // ignore the workspace name, use section name instead in the future
    // skip the workspace view
    for (var i = 1; i < views.length; i++) {
      final view = views[i];

      if (i >= lowerBound && i < upperBound) {
        if (!hasAddedEllipsis) {
          hasAddedEllipsis = true;
          children.addAll([
            const FlowyText.regular(' ... '),
            const FlowySvg(FlowySvgs.title_bar_divider_s),
          ]);
        }
        continue;
      }

      final child = FlowyTooltip(
        key: ValueKey(view.id),
        message: view.name,
        child: ViewTitle(
          view: view,
          behavior: i == views.length - 1 && !view.isLocked && isEditable
              ? ViewTitleBehavior.editable // only the last one is editable
              : ViewTitleBehavior.uneditable, // others are not editable
          onUpdated: () {
            if (context.mounted) {
              context
                  .read<ViewTitleBarBloc>()
                  .add(const ViewTitleBarEvent.reload());
            }
          },
        ),
      );

      children.add(child);

      if (i != views.length - 1) {
        // if not the last one, add a divider
        children.add(const FlowySvg(FlowySvgs.title_bar_divider_s));
      }
    }

    // add the section icon in the breadcrumb
    children.addAll([
      HSpace(theme.spacing.xs),
      BlocBuilder<PageAccessLevelBloc, PageAccessLevelState>(
        buildWhen: (previous, current) =>
            previous.sectionType != current.sectionType,
        builder: (context, state) {
          return _buildSectionIcon(context, state);
        },
      ),
    ]);

    return children;
  }

  List<Widget> _buildDeletedTitle(BuildContext context, ViewPB view) {
    return [
      const TrashBreadcrumb(),
      const FlowySvg(FlowySvgs.title_bar_divider_s),
      FlowyTooltip(
        key: ValueKey(view.id),
        message: view.name,
        child: ViewTitle(
          view: view,
          onUpdated: () => context
              .read<ViewTitleBarBloc>()
              .add(const ViewTitleBarEvent.reload()),
        ),
      ),
    ];
  }

  Widget _buildSectionIcon(
    BuildContext context,
    PageAccessLevelState pageAccessLevelState,
  ) {
    final theme = AppFlowyTheme.of(context);

    final iconName = switch (pageAccessLevelState.sectionType) {
      SharedSectionType.public => FlowySvgs.public_section_icon_m,
      SharedSectionType.private => FlowySvgs.private_section_icon_m,
      SharedSectionType.shared => FlowySvgs.shared_section_icon_m,
    };

    final icon = FlowySvg(
      iconName,
      color: theme.iconColorScheme.tertiary,
      size: Size.square(20),
    );

    final text = switch (pageAccessLevelState.sectionType) {
      SharedSectionType.public => 'Team space',
      SharedSectionType.private => 'Private',
      SharedSectionType.shared => 'Shared',
    };

    return Row(
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        HSpace(theme.spacing.xs),
        icon,
        const HSpace(4.0), // ask designer to provide the spacing
        Text(
          text,
          style: theme.textStyle.caption
              .enhanced(color: theme.textColorScheme.tertiary),
        ),
        HSpace(theme.spacing.xs),
      ],
    );
  }
}

class TrashBreadcrumb extends StatelessWidget {
  const TrashBreadcrumb({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        useIntrinsicWidth: true,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        onTap: () {
          getIt<MenuSharedState>().latestOpenView = null;
          getIt<TabsBloc>().add(
            TabsEvent.openPlugin(
              plugin: makePlugin(pluginType: PluginType.trash),
            ),
          );
        },
        text: Row(
          children: [
            const FlowySvg(FlowySvgs.trash_s, size: Size.square(14)),
            const HSpace(4.0),
            FlowyText.regular(
              LocaleKeys.trash_text.tr(),
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
              figmaLineHeight: 18.0,
            ),
          ],
        ),
      ),
    );
  }
}

enum ViewTitleBehavior {
  editable,
  uneditable,
}

class ViewTitle extends StatefulWidget {
  const ViewTitle({
    super.key,
    required this.view,
    this.behavior = ViewTitleBehavior.editable,
    required this.onUpdated,
  });

  final ViewPB view;
  final ViewTitleBehavior behavior;
  final VoidCallback onUpdated;

  @override
  State<ViewTitle> createState() => _ViewTitleState();
}

class _ViewTitleState extends State<ViewTitle> {
  final popoverController = PopoverController();
  final textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    popoverController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.behavior == ViewTitleBehavior.editable;

    return BlocProvider(
      create: (_) =>
          ViewTitleBloc(view: widget.view)..add(const ViewTitleEvent.initial()),
      child: BlocConsumer<ViewTitleBloc, ViewTitleState>(
        listenWhen: (previous, current) {
          if (previous.view == null || current.view == null) {
            return false;
          }

          return previous.view != current.view;
        },
        listener: (_, state) {
          _resetTextEditingController(state);
          widget.onUpdated();
        },
        builder: (context, state) {
          // root view
          if (widget.view.parentViewId.isEmpty) {
            return Row(
              children: [
                FlowyText.regular(state.name),
                const HSpace(4.0),
              ],
            );
          } else if (widget.view.isSpace) {
            return _buildSpaceTitle(context, state);
          } else if (isEditable) {
            return _buildEditableViewTitle(context, state);
          } else {
            return _buildUnEditableViewTitle(context, state);
          }
        },
      ),
    );
  }

  Widget _buildSpaceTitle(BuildContext context, ViewTitleState state) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: _buildIconAndName(context, state, false),
    );
  }

  Widget _buildUnEditableViewTitle(BuildContext context, ViewTitleState state) {
    return Listener(
      onPointerDown: (_) => context.read<TabsBloc>().openPlugin(widget.view),
      child: SizedBox(
        height: 32.0,
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          text: _buildIconAndName(context, state, false),
        ),
      ),
    );
  }

  Widget _buildEditableViewTitle(BuildContext context, ViewTitleState state) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 44,
      ),
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 6),
      popupBuilder: (context) {
        // icon + textfield
        _resetTextEditingController(state);
        return RenameViewPopover(
          view: widget.view,
          name: widget.view.name,
          popoverController: popoverController,
          icon: widget.view.defaultIcon(),
          emoji: state.icon,
          tabs: const [
            PickerTabType.emoji,
            PickerTabType.icon,
            PickerTabType.custom,
          ],
        );
      },
      child: SizedBox(
        height: 32.0,
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          text: _buildIconAndName(context, state, true),
        ),
      ),
    );
  }

  Widget _buildIconAndName(
    BuildContext context,
    ViewTitleState state,
    bool isEditable,
  ) {
    final spaceIcon = state.view?.buildSpaceIconSvg(context);
    return SingleChildScrollView(
      child: Row(
        children: [
          if (state.icon.isNotEmpty) ...[
            RawEmojiIconWidget(emoji: state.icon, emojiSize: 14.0),
            const HSpace(4.0),
          ],
          if (state.view?.isSpace == true && spaceIcon != null) ...[
            SpaceIcon(
              dimension: 14,
              svgSize: 8.5,
              space: state.view!,
              cornerRadius: 4,
            ),
            const HSpace(6.0),
          ],
          Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: FlowyText.regular(
              state.name.isEmpty
                  ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
                  : state.name,
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
              figmaLineHeight: 18.0,
            ),
          ),
        ],
      ),
    );
  }

  void _resetTextEditingController(ViewTitleState state) {
    textEditingController
      ..text = state.name
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: state.name.length,
      );
  }
}

class LockedPageStatus extends StatelessWidget {
  const LockedPageStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFD95A0B);
    return FlowyTooltip(
      message: LocaleKeys.lockPage_lockTooltip.tr(),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: color),
            borderRadius: BorderRadius.circular(6),
          ),
          color: context.lockedPageButtonBackground,
        ),
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: const EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 4.0,
          ),
          iconPadding: 4.0,
          text: FlowyText.regular(
            LocaleKeys.lockPage_lockPage.tr(),
            color: color,
            fontSize: 12.0,
          ),
          hoverColor: color.withValues(alpha: 0.1),
          leftIcon: FlowySvg(
            FlowySvgs.lock_page_fill_s,
            blendMode: null,
          ),
          onTap: () => context.read<PageAccessLevelBloc>().add(
                const PageAccessLevelEvent.unlock(),
              ),
        ),
      ),
    );
  }
}

class ReLockedPageStatus extends StatelessWidget {
  const ReLockedPageStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final iconColor = const Color(0xFF8F959E);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: iconColor),
          borderRadius: BorderRadius.circular(6),
        ),
        color: context.lockedPageButtonBackground,
      ),
      child: FlowyButton(
        useIntrinsicWidth: true,
        margin: const EdgeInsets.symmetric(
          horizontal: 4.0,
          vertical: 4.0,
        ),
        iconPadding: 4.0,
        text: FlowyText.regular(
          LocaleKeys.lockPage_reLockPage.tr(),
          fontSize: 12.0,
        ),
        leftIcon: FlowySvg(
          FlowySvgs.unlock_page_s,
          color: iconColor,
          blendMode: null,
        ),
        onTap: () => context.read<PageAccessLevelBloc>().add(
              const PageAccessLevelEvent.lock(),
            ),
      ),
    );
  }
}

extension on BuildContext {
  Color get lockedPageButtonBackground {
    if (Theme.of(this).brightness == Brightness.light) {
      return Colors.white.withValues(alpha: 0.75);
    }
    return Color(0xB21B1A22);
  }
}
