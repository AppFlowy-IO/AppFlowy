import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/rename_view_dialog.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ViewItemOnSelected = void Function(ViewPB);

class ViewItem extends StatelessWidget {
  const ViewItem({
    super.key,
    required this.view,
    this.parentView,
    required this.categoryType,
    required this.level,
    this.leftPadding = 10,
    required this.onSelected,
    this.onTertiarySelected,
    this.isFirstChild = false,
    this.isDraggable = true,
    required this.isFeedback,
  });

  final ViewPB view;
  final ViewPB? parentView;

  final FolderCategoryType categoryType;

  // indicate the level of the view item
  // used to calculate the left padding
  final int level;

  // the left padding of the view item for each level
  // the left padding of the each level = level * leftPadding
  final double leftPadding;

  // Selected by normal conventions
  final ViewItemOnSelected onSelected;

  // Selected by middle mouse button
  final ViewItemOnSelected? onTertiarySelected;

  // used for indicating the first child of the parent view, so that we can
  // add top border to the first child
  final bool isFirstChild;

  // it should be false when it's rendered as feedback widget inside DraggableItem
  final bool isDraggable;

  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewBloc(view: view)..add(const ViewEvent.initial()),
      child: BlocConsumer<ViewBloc, ViewState>(
        listenWhen: (p, c) =>
            c.lastCreatedView != null &&
            p.lastCreatedView?.id != c.lastCreatedView!.id,
        listener: (context, state) =>
            context.read<TabsBloc>().openPlugin(state.lastCreatedView!),
        builder: (context, state) {
          // don't remove this code. it's related to the backend service.
          view.childViews
            ..clear()
            ..addAll(state.childViews);
          return InnerViewItem(
            view: state.view,
            parentView: parentView,
            childViews: state.childViews,
            categoryType: categoryType,
            level: level,
            leftPadding: leftPadding,
            showActions: state.isEditing,
            isExpanded: state.isExpanded,
            onSelected: onSelected,
            onTertiarySelected: onTertiarySelected,
            isFirstChild: isFirstChild,
            isDraggable: isDraggable,
            isFeedback: isFeedback,
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
    required this.parentView,
    required this.childViews,
    required this.categoryType,
    this.isDraggable = true,
    this.isExpanded = true,
    required this.level,
    required this.leftPadding,
    required this.showActions,
    required this.onSelected,
    this.onTertiarySelected,
    this.isFirstChild = false,
    required this.isFeedback,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final List<ViewPB> childViews;
  final FolderCategoryType categoryType;

  final bool isDraggable;
  final bool isExpanded;
  final bool isFirstChild;
  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  final int level;
  final double leftPadding;

  final bool showActions;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;

  @override
  Widget build(BuildContext context) {
    Widget child = SingleInnerViewItem(
      view: view,
      parentView: parentView,
      level: level,
      showActions: showActions,
      categoryType: categoryType,
      onSelected: onSelected,
      onTertiarySelected: onTertiarySelected,
      isExpanded: isExpanded,
      isDraggable: isDraggable,
      leftPadding: leftPadding,
      isFeedback: isFeedback,
    );

    // if the view is expanded and has child views, render its child views
    if (isExpanded && childViews.isNotEmpty) {
      final children = childViews.map((childView) {
        return ViewItem(
          key: ValueKey('${categoryType.name} ${childView.id}'),
          parentView: view,
          categoryType: categoryType,
          isFirstChild: childView.id == childViews.first.id,
          view: childView,
          level: level + 1,
          onSelected: onSelected,
          onTertiarySelected: onTertiarySelected,
          isDraggable: isDraggable,
          leftPadding: leftPadding,
          isFeedback: isFeedback,
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
    if (isDraggable && !isReferencedDatabaseView(view, parentView)) {
      child = DraggableViewItem(
        isFirstChild: isFirstChild,
        view: view,
        child: child,
        feedback: (context) {
          return ViewItem(
            view: view,
            parentView: parentView,
            categoryType: categoryType,
            level: level,
            onSelected: onSelected,
            onTertiarySelected: onTertiarySelected,
            isDraggable: false,
            leftPadding: leftPadding,
            isFeedback: true,
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
    required this.parentView,
    required this.isExpanded,
    required this.level,
    required this.leftPadding,
    this.isDraggable = true,
    required this.categoryType,
    required this.showActions,
    required this.onSelected,
    this.onTertiarySelected,
    required this.isFeedback,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final bool isExpanded;
  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  final int level;
  final double leftPadding;

  final bool isDraggable;
  final bool showActions;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final FolderCategoryType categoryType;

  @override
  State<SingleInnerViewItem> createState() => _SingleInnerViewItemState();
}

class _SingleInnerViewItemState extends State<SingleInnerViewItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isFeedback) {
      return _buildViewItem(false);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: FlowyHover(
        isSelected: () =>
            widget.showActions ||
            getIt<MenuSharedState>().latestOpenView?.id == widget.view.id,
        child: _buildViewItem(_isHovering),
      ),
    );
  }

  Widget _buildViewItem(bool onHover) {
    final children = [
      // expand icon
      _buildLeftIcon(),
      // icon
      SizedBox.square(
        dimension: 16,
        child: widget.view.defaultIcon(),
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
      // only support add button for document layout
      if (widget.view.layout == ViewLayoutPB.Document) {
        // + button
        children.add(_buildViewAddButton(context));
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => widget.onSelected(widget.view),
      onTertiaryTapDown: (_) => widget.onTertiarySelected?.call(widget.view),
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

  // > button or · button
  // show > if the view is expandable.
  // show · if the view can't contain child views.
  Widget _buildLeftIcon() {
    if (isReferencedDatabaseView(widget.view, widget.parentView)) {
      return const _DotIconWidget();
    }

    final svg = widget.isExpanded
        ? FlowySvgs.drop_menu_show_m
        : FlowySvgs.drop_menu_hide_m;
    return GestureDetector(
      child: FlowySvg(
        svg,
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
            createViewAndShowRenameDialogIfNeeded(
              context,
              _convertLayoutToHintText(pluginBuilder.layoutType!),
              (viewName) {
                if (viewName.isNotEmpty) {
                  context.read<ViewBloc>().add(
                        ViewEvent.createView(
                          viewName,
                          pluginBuilder.layoutType!,
                          openAfterCreated: openAfterCreated,
                        ),
                      );
                }
              },
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
              context.read<TabsBloc>().openTab(widget.view);
              break;
            default:
              throw UnsupportedError('$action is not supported');
          }
        },
      ),
    );
  }

  String _convertLayoutToHintText(ViewLayoutPB layout) {
    switch (layout) {
      case ViewLayoutPB.Document:
        return LocaleKeys.newDocumentText.tr();
      case ViewLayoutPB.Grid:
        return LocaleKeys.newGridText.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.newBoardText.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.newCalendarText.tr();
    }
    return LocaleKeys.newPageText.tr();
  }
}

class _DotIconWidget extends StatelessWidget {
  const _DotIconWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// workaround: we should use view.isEndPoint or something to check if the view can contain child views. But currently, we don't have that field.
bool isReferencedDatabaseView(ViewPB view, ViewPB? parentView) {
  if (parentView == null) {
    return false;
  }
  return view.layout.isDatabaseView && parentView.layout.isDatabaseView;
}
