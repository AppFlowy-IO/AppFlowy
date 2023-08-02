import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewItem extends StatelessWidget {
  const ViewItem({
    super.key,
    required this.view,
    required this.categoryType,
    required this.level,
    this.leftPadding = 10,
    required this.onSelected,
    this.isFirstChild = false,
    this.isDraggable = true,
  });

  final ViewPB view;

  final SidebarFolderCategoryType categoryType;

  // indicate the level of the view item
  // used to calculate the left padding
  final int level;

  // the left padding of the view item for each level
  // the left padding of the each level = level * leftPadding
  final double leftPadding;

  final void Function(ViewPB) onSelected;

  // used for indicating the first child of the parent view, so that we can
  // add top border to the first child
  final bool isFirstChild;

  // it should be false when it's rendered as feedback widget inside DraggableItem
  final bool isDraggable;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewBloc(view: view)..add(const ViewEvent.initial()),
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          return InnerViewItem(
            view: state.view,
            childViews: state.childViews,
            categoryType: categoryType,
            level: level,
            leftPadding: leftPadding,
            showActions: state.isEditing,
            isExpanded: state.isExpanded,
            onSelected: onSelected,
            isFirstChild: isFirstChild,
            isDraggable: isDraggable,
          );
        },
      ),
    );
  }
}

class InnerViewItem extends StatelessWidget {
  const InnerViewItem({
    super.key,
    required this.view,
    required this.childViews,
    required this.categoryType,
    this.isDraggable = true,
    this.isExpanded = true,
    required this.level,
    this.leftPadding = 10,
    required this.showActions,
    required this.onSelected,
    this.isFirstChild = false,
  });

  final ViewPB view;
  final List<ViewPB> childViews;
  final SidebarFolderCategoryType categoryType;

  final bool isDraggable;
  final bool isExpanded;
  final bool isFirstChild;

  final int level;
  final double leftPadding;

  final bool showActions;
  final void Function(ViewPB) onSelected;

  @override
  Widget build(BuildContext context) {
    Widget child = SingleInnerViewItem(
      view: view,
      level: level,
      showActions: showActions,
      onSelected: onSelected,
      isExpanded: isExpanded,
    );

    // if the view is expanded and has child views, render its child views
    if (isExpanded && childViews.isNotEmpty) {
      final children = childViews.map((childView) {
        return ViewItem(
          key: ValueKey('${categoryType.name} ${childView.id}'),
          categoryType: categoryType,
          isFirstChild: childView.id == childViews.first.id,
          view: childView,
          level: level + 1,
          onSelected: onSelected,
          isDraggable: isDraggable,
        );
      }).toList();

      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          ...children,
        ],
      );
    }

    // wrap the child with DraggableItem if isDraggable is true
    if (isDraggable) {
      child = DraggableViewItem(
        isFirstChild: isFirstChild,
        view: view,
        child: child,
        feedback: (context) {
          return ViewItem(
            view: view,
            categoryType: categoryType,
            level: level,
            onSelected: onSelected,
            isDraggable: false,
          );
        },
      );
    } else {
      // keep the same height of the DraggableItem
      child = Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: child,
      );
    }

    return child;
  }
}

class SingleInnerViewItem extends StatefulWidget {
  const SingleInnerViewItem({
    super.key,
    required this.view,
    required this.isExpanded,
    required this.level,
    this.leftPadding = 10,
    required this.showActions,
    required this.onSelected,
  });

  final ViewPB view;
  final bool isExpanded;

  final int level;
  final double leftPadding;

  final bool showActions;
  final void Function(ViewPB) onSelected;

  @override
  State<SingleInnerViewItem> createState() => _SingleInnerViewItemState();
}

class _SingleInnerViewItemState extends State<SingleInnerViewItem> {
  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      style: HoverStyle(
        hoverColor: Theme.of(context).colorScheme.secondary,
      ),
      buildWhenOnHover: () => !widget.showActions,
      builder: (_, onHover) => _buildViewItem(onHover),
      isSelected: () =>
          widget.showActions ||
          getIt<MenuSharedState>().latestOpenView?.id == widget.view.id,
    );
  }

  Widget _buildViewItem(bool onHover) {
    final children = [
      // expand icon
      _buildExpandedIcon(),
      const HSpace(7),
      // icon
      SizedBox.square(
        dimension: 16,
        child: widget.view.icon(),
      ),
      const HSpace(5),
      // title
      Expanded(
        child: FlowyText.regular(
          widget.view.name,
          overflow: TextOverflow.ellipsis,
        ),
      )
    ];

    // hover action
    if (widget.showActions || onHover) {
      // ··· more action button
      children.add(_buildViewMoreActionButton(context));
      // + button
      children.add(_buildViewAddButton(context));
    }

    return GestureDetector(
      onTap: () => widget.onSelected(widget.view),
      child: SizedBox(
        height: 26,
        child: Padding(
          padding: EdgeInsets.only(left: widget.level * widget.leftPadding),
          child: Row(
            children: children,
          ),
        ),
      ),
    );
  }

  // > button
  Widget _buildExpandedIcon() {
    final name =
        widget.isExpanded ? 'home/drop_down_show' : 'home/drop_down_hide';
    return GestureDetector(
      child: FlowySvg(
        name: name,
        size: const Size.square(16.0),
      ),
      onTap: () => context
          .read<ViewBloc>()
          .add(ViewEvent.setIsExpanded(!widget.isExpanded)),
    );
  }

  // + button
  Widget _buildViewAddButton(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.menuAppHeader_addPageTooltip.tr(),
      child: ViewAddButton(
        parentViewId: widget.view.id,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onSelected: (
          pluginBuilder,
          name,
          initialDataBytes,
          openAfterCreated,
          createNewView,
        ) {
          if (createNewView) {
            context.read<ViewBloc>().add(
                  ViewEvent.createView(
                    name ?? LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                    pluginBuilder.layoutType!,
                    openAfterCreated: openAfterCreated,
                  ),
                );
          }
          context.read<ViewBloc>().add(
                const ViewEvent.setIsExpanded(true),
              );
        },
      ),
    );
  }

  // ··· more action button
  Widget _buildViewMoreActionButton(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.menuAppHeader_moreButtonToolTip.tr(),
      child: ViewMoreActionButton(
        view: widget.view,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onAction: (action) {
          switch (action) {
            case ViewMoreActionType.favorite:
            case ViewMoreActionType.unFavorite:
              context
                  .read<FavoriteBloc>()
                  .add(FavoriteEvent.toggle(widget.view));
              break;
            case ViewMoreActionType.rename:
              NavigatorTextFieldDialog(
                title: LocaleKeys.disclosureAction_rename.tr(),
                autoSelectAllText: true,
                value: widget.view.name,
                confirm: (newValue) {
                  context.read<ViewBloc>().add(ViewEvent.rename(newValue));
                },
              ).show(context);
              break;
            case ViewMoreActionType.delete:
              context.read<ViewBloc>().add(const ViewEvent.delete());
              break;
            case ViewMoreActionType.duplicate:
              context.read<ViewBloc>().add(const ViewEvent.duplicate());
              break;
            case ViewMoreActionType.openInNewTab:
              context.read<TabsBloc>().add(
                    TabsEvent.openTab(
                      plugin: widget.view.plugin(),
                      view: widget.view,
                    ),
                  );
              break;
            default:
              throw UnsupportedError('$action is not supported');
          }
        },
      ),
    );
  }
}
